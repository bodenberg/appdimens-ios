#!/usr/bin/env python3
"""Generates the Swift catalogs (core + satellite modules) mirroring the
dynamic-android naming surface.

Every accessor is emitted twice on `DimensNumber`:

* ``16.sdp``                 — ambient window, returns ``CGFloat`` (Compose style)
* ``16.sdp(configuration)``  — explicit window, returns ``Double`` points (code style)

Families (Android names): sdp/hdp/wdp (+Ph/Lh/Pw/Lw inverter variants),
ssp/hsp/wsp/sem/hem/wem (+inverter variants), sei/hei/wei, Px variants
(iOS ``<name>Px`` and Android ``<family>Px<flags><inverter>`` spellings), and
the Rotate/Mode/Qualifier/Screen facilitators (+Px, +Plain, +PlainPx).

Satellite prefixes: p=percent, pw=power, f=fluid, a=auto, d=density,
dg=diagonal, fl=fill, ft=fit, i=interpolated, log=logarithmic, pr=perimeter.

Run: python3 scripts/generate_catalogs.py
"""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

FLAGS = [("", False, False), ("a", True, False), ("i", False, True), ("ia", True, True)]

SW_INV = [("", "default"), ("Ph", "swToPh"), ("Lh", "swToLh"), ("Pw", "swToPw"), ("Lw", "swToLw")]
H_INV = [("", "default"), ("Lw", "phToLw"), ("Pw", "lhToPw")]
W_INV = [("", "default"), ("Lh", "pwToLh"), ("Ph", "lwToPh")]

DP_FAMILIES = [("sdp", "smallWidth", SW_INV), ("hdp", "height", H_INV), ("wdp", "width", W_INV)]

SP_FAMILIES = [
    ("ssp", "smallWidth", True, SW_INV), ("hsp", "height", True, H_INV), ("wsp", "width", True, W_INV),
    ("sem", "smallWidth", False, SW_INV), ("hem", "height", False, H_INV), ("wem", "width", False, W_INV),
]

EI_FAMILIES = [("sei", "smallWidth"), ("hei", "height"), ("wei", "width")]

BRANCH_FAMILIES = [("sdp", "smallWidth", False), ("hdp", "height", False), ("wdp", "width", False),
                   ("ssp", "smallWidth", True), ("hsp", "height", True), ("wsp", "width", True)]

AMBIENT = "AppDimens._withAmbient"


def b(value):
    return "true" if value else "false"


def kernel_call(kernel, expr, cfg, qualifier, inverter, ar, ignore, k="nil"):
    return (f"AppDimens.{kernel}({expr}, configuration: {cfg}, qualifier: {qualifier}, inverter: {inverter}, "
            f"ignoreMultiWindows: {ignore}, applyAspectRatio: {ar}, sensitivityK: {k})")


def sp_expr(kernel, expr, cfg, qualifier, inverter, ar, ignore, font_scale, k="nil"):
    base = kernel_call(kernel, expr, cfg, qualifier, inverter, ar, ignore, k)
    if font_scale is True:
        return f"{base} * {cfg}.fontScale"
    if font_scale is False:
        return base
    return f"({font_scale} ? {base} * {cfg}.fontScale : {base})"


def emit_pair(out, name, body_for_cfg, doc=None):
    """Explicit-config func + ambient var for the same accessor."""
    if doc:
        out.append(f"    /// {doc}")
    out.append(f"    @inlinable func {name}(_ configuration: DimensConfiguration) -> Double {{ {body_for_cfg('configuration')} }}")
    out.append(f"    @inlinable var {name}: CGFloat {{ CGFloat({AMBIENT} {{ c in {body_for_cfg('c')} }}) }}")


def gen_simple(prefix, kernel, out):
    seen = set()

    def add(name, fn, doc=None):
        if name in seen:
            return
        seen.add(name)
        emit_pair(out, name, fn, doc)

    out.append("    // ── dp families ─────────────────────────────────────────────────────")
    for fam, q, invs in DP_FAMILIES:
        for inv_s, inv in invs:
            for flag, ar, ignore in FLAGS:
                name = f"{prefix}{fam}{inv_s}{flag}"
                dp = (lambda q=q, inv=inv, ar=ar, ignore=ignore:
                      lambda cfg: kernel_call(kernel, "dimensValue", cfg, f".{q}", f".{inv}", b(ar), b(ignore)))()
                px = (lambda dp=dp: lambda cfg: f"{dp(cfg)} * {cfg}.displayScale")()
                add(name, dp)
                add(f"{name}Px", px)
                if inv_s:
                    add(f"{prefix}{fam}Px{flag}{inv_s}", px)  # Android spelling (sdpPxaPh)

    out.append("    // ── sp families ─────────────────────────────────────────────────────")
    for fam, q, fs, invs in SP_FAMILIES:
        for inv_s, inv in invs:
            for flag, ar, ignore in FLAGS:
                name = f"{prefix}{fam}{inv_s}{flag}"
                sp = (lambda q=q, inv=inv, ar=ar, ignore=ignore, fs=fs:
                      lambda cfg: sp_expr(kernel, "dimensValue", cfg, f".{q}", f".{inv}", b(ar), b(ignore), fs))()
                px = (lambda sp=sp: lambda cfg: f"({sp(cfg)}) * {cfg}.displayScale")()
                add(name, sp)
                add(f"{name}Px", px)
                add(f"{prefix}{fam}Px{flag}{inv_s}", px)  # Android spelling (sspPxa, sspPxaLh)

    out.append("    // ── sei/hei/wei — pixels without font scale ─────────────────────────")
    for fam, q in EI_FAMILIES:
        for flag, ar, ignore in FLAGS:
            name = f"{prefix}{fam}{flag}"
            fn = (lambda q=q, ar=ar, ignore=ignore:
                  lambda cfg: f"{kernel_call(kernel, 'dimensValue', cfg, f'.{q}', '.default', b(ar), b(ignore))} * {cfg}.displayScale")()
            add(name, fn)


OPTS = "ignoreMultiWindows: Bool = false, applyAspectRatio: Bool = false, customSensitivityK: Double? = nil"


def gen_branches(prefix, kernel, out):
    out.append("    // ── facilitators (Rotate / Mode / Qualifier / Screen) ───────────────")
    for fam, q, is_sp in BRANCH_FAMILIES:
        font_param = "fontScale: Bool = true, " if is_sp else ""
        kinds = {
            "Rotate": (f"_ rotationValue: Double, finalQualifierResolver: DpQualifier = .{q}, "
                       f"orientation: Orientation = .landscape, {font_param}{OPTS}",
                       "AppDimensPlain.isOrientationMatch(cfg, orientation)", "rotationValue",
                       "finalQualifierResolver"),
            "Mode": (f"_ modeValue: Double, _ uiModeType: UiModeType, finalQualifierResolver: DpQualifier? = nil, "
                     f"{font_param}{OPTS}",
                     "cfg.uiMode == uiModeType", "modeValue", f"finalQualifierResolver ?? .{q}"),
            "Qualifier": (f"_ qualifiedValue: Double, _ qualifierType: DpQualifier, _ qualifierValue: Double, "
                          f"finalQualifierResolver: DpQualifier? = nil, {font_param}{OPTS}",
                          "cfg.dimension(qualifierType) >= qualifierValue", "qualifiedValue",
                          f"finalQualifierResolver ?? .{q}"),
            "Screen": (f"_ screenValue: Double, _ uiModeType: UiModeType, _ qualifierType: DpQualifier, "
                       f"_ qualifierValue: Double, finalQualifierResolver: DpQualifier? = nil, {font_param}{OPTS}",
                       "cfg.uiMode == uiModeType && cfg.dimension(qualifierType) >= qualifierValue",
                       "screenValue", f"finalQualifierResolver ?? .{q}"),
        }
        for kind, (params, cond, value, final_q) in kinds.items():
            for variant in ("", "Px", "Plain", "PlainPx"):
                name = f"{prefix}{fam}{kind}{variant}"
                is_px = variant.endswith("Px")
                plain = variant.startswith("Plain")

                def body(cfg, cond=cond, value=value, final_q=final_q, is_px=is_px, plain=plain):
                    c = cond.replace("cfg", cfg)
                    fs = "fontScale" if is_sp else None

                    def resolve(expr, qual):
                        if is_sp:
                            r = sp_expr(kernel, expr, cfg, qual, ".default", "applyAspectRatio",
                                        "ignoreMultiWindows", fs, "customSensitivityK")
                        else:
                            r = kernel_call(kernel, expr, cfg, qual, ".default", "applyAspectRatio",
                                            "ignoreMultiWindows", "customSensitivityK")
                        return f"({r}) * {cfg}.displayScale" if is_px else r

                    if plain:
                        return f"{c} ? {resolve(value, final_q)} : dimensValue"
                    return f"{c} ? {resolve(value, final_q)} : {resolve('dimensValue', '.' + q)}"

                out.append(f"    @inlinable func {name}({params}, _ configuration: DimensConfiguration) -> Double {{")
                out.append(f"        {body('configuration')}")
                out.append("    }")
                out.append(f"    @inlinable func {name}({params}) -> CGFloat {{")
                out.append(f"        CGFloat({AMBIENT} {{ c in {body('c')} }})")
                out.append("    }")


BUILDER_NAMES = {
    "percent": "percent", "power": "power", "fluid": "fluid", "auto": "auto", "density": "density",
    "diagonal": "diagonal", "fill": "fill", "fit": "fit", "interpolated": "interpolated",
    "logarithmic": "logarithmic", "perimeter": "perimeter",
}


def gen_builders(strategy, out):
    if strategy is None:
        return
    n = BUILDER_NAMES[strategy]
    out.append("    // ── conditional builders (Android `Number.<strategy>Dp()` / `<strategy>Sp()`) ──")
    out.append(f"    /// Android `Number.{n}Dp()` — conditional {n} builder.")
    out.append(f"    @inlinable func {n}Dp() -> DimenBuilder {{ DimenBuilder(dimensValue, strategy: .{strategy}) }}")
    out.append(f"    /// Android `Number.{n}ScaledDp()` (code API spelling).")
    out.append(f"    @inlinable func {n}ScaledDp() -> DimenBuilder {{ DimenBuilder(dimensValue, strategy: .{strategy}) }}")
    out.append(f"    /// Android `Number.{n}Sp()` — conditional {n} text builder.")
    out.append(f"    @inlinable func {n}Sp(fontScale: Bool = true) -> DimenBuilder {{")
    out.append(f"        DimenBuilder(dimensValue, strategy: .{strategy}, text: true, fontScale: fontScale)")
    out.append("    }")


def generate(prefix, kernel, module_dir, doc, strategy=None, filename="Catalog.swift"):
    out = ["// Generated by scripts/generate_catalogs.py — do not edit.",
           f"// {doc}"]
    if prefix:
        out.append("@_exported import AppDimens")
    out += ["import Foundation", "", "public extension DimensNumber {"]
    gen_simple(prefix, kernel, out)
    gen_branches(prefix, kernel, out)
    gen_builders(strategy, out)
    out.append("}")
    path = os.path.join(ROOT, "Sources", module_dir, filename)
    with open(path, "w") as f:
        f.write("\n".join(out) + "\n")
    print(f"wrote {os.path.relpath(path, ROOT)} ({len(out)} lines)")


SATELLITES = [
    ("p", "percentDp", "AppDimensPercent", "percent satellite — `p*` catalog", "percent"),
    ("pw", "powerDp", "AppDimensPower", "power satellite — `pw*` catalog", "power"),
    ("f", "fluidDp", "AppDimensFluid", "fluid satellite — `f*` catalog", "fluid"),
    ("a", "autoDp", "AppDimensAuto", "auto satellite — `a*` catalog", "auto"),
    ("d", "densityDp", "AppDimensDensity", "density satellite — `d*` catalog", "density"),
    ("dg", "diagonalDp", "AppDimensDiagonal", "diagonal satellite — `dg*` catalog", "diagonal"),
    ("fl", "fillDp", "AppDimensFill", "fill satellite — `fl*` catalog", "fill"),
    ("ft", "fitDp", "AppDimensFit", "fit satellite — `ft*` catalog", "fit"),
    ("i", "interpolatedDp", "AppDimensInterpolated", "interpolated satellite — `i*` catalog", "interpolated"),
    ("log", "logarithmicDp", "AppDimensLogarithmic", "logarithmic satellite — `log*` catalog", "logarithmic"),
    ("pr", "perimeterDp", "AppDimensPerimeter", "perimeter satellite — `pr*` catalog", "perimeter"),
]

if __name__ == "__main__":
    generate("", "scaledDp", "AppDimens",
             "Core scaled catalog — Android-familiar `sdp`/`ssp` naming.", filename="CoreCatalog.swift")
    for prefix, kernel, module, doc, strategy in SATELLITES:
        generate(prefix, kernel, module, doc, strategy)
