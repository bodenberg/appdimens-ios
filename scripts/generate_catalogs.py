#!/usr/bin/env python3
"""Generates Swift catalog files (core + satellite modules) mirroring the
Android-familiar dynamic-android 3.1.7 naming surface.

Families (Android names): sdp/hdp/wdp (+Ph/Lh/Pw/Lw inverter variants),
sdpRotate/sdpMode/sdpQualifier/sdpScreen (+Px), Px variants of the base
families, ssp/hsp/wsp/sem/hem/wem (+inverter variants + Px), sei/hei/wei.

Satellite prefixes: p=percent, pw=power, f=fluid, a=auto, d=density,
dg=diagonal, fl=fill, ft=fit, i=interpolated, log=logarithmic, pr=perimeter.
"""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

FLAGS = [("", False, False), ("a", True, False), ("i", False, True), ("ia", True, True)]

DP_FAMILIES = [
    ("sdp", "smallWidth", [("", "default"), ("Ph", "swToPh"), ("Lh", "swToLh"), ("Pw", "swToPw"), ("Lw", "swToLw")]),
    ("hdp", "height",     [("", "default"), ("Lw", "phToLw"), ("Pw", "lhToPw")]),
    ("wdp", "width",      [("", "default"), ("Lh", "pwToLh"), ("Ph", "lwToPh")]),
]

SP_FAMILIES = [
    ("ssp", "smallWidth", True,  [("", "default"), ("Ph", "swToPh"), ("Lh", "swToLh"), ("Pw", "swToPw"), ("Lw", "swToLw")]),
    ("hsp", "height",     True,  [("", "default"), ("Lw", "phToLw"), ("Pw", "lhToPw")]),
    ("wsp", "width",      True,  [("", "default"), ("Lh", "pwToLh"), ("Ph", "lwToPh")]),
    ("sem", "smallWidth", False, [("", "default"), ("Ph", "swToPh"), ("Lh", "swToLh"), ("Pw", "swToPw"), ("Lw", "swToLw")]),
    ("hem", "height",     False, [("", "default"), ("Lw", "phToLw"), ("Pw", "lhToPw")]),
    ("wem", "width",      False, [("", "default"), ("Lh", "pwToLh"), ("Ph", "lwToPh")]),
]

EI_FAMILIES = [("sei", "smallWidth"), ("hei", "height"), ("wei", "width")]

BRANCH_FAMILIES = [("sdp", "smallWidth", False), ("hdp", "height", False), ("wdp", "width", False),
                   ("ssp", "smallWidth", True), ("hsp", "height", True), ("wsp", "width", True)]


def dp_call(kernel, expr, qualifier, inverter, ar, ignore):
    return (f"AppDimens.{kernel}({expr}, configuration: configuration, "
            f"qualifier: .{qualifier}, inverter: .{inverter}, "
            f"ignoreMultiWindows: {str(ignore).lower()}, applyAspectRatio: {str(ar).lower()})")


def sp_call(kernel, expr, qualifier, inverter, ar, ignore, font_scale, sp_kernel):
    if sp_kernel is not None:
        return (f"AppDimens.{sp_kernel}({expr}, configuration: configuration, "
                f"qualifier: .{qualifier}, fontScale: {str(font_scale).lower()}, inverter: .{inverter}, "
                f"ignoreMultiWindows: {str(ignore).lower()}, applyAspectRatio: {str(ar).lower()})")
    base = dp_call(kernel, expr, qualifier, inverter, ar, ignore)
    return f"({base} * configuration.fontScale)" if font_scale else base


def gen_dp_members(prefix, kernel, out):
    for fam, qualifier, invs in DP_FAMILIES:
        for inv_suffix, inverter in invs:
            for suffix, ar, ignore in FLAGS:
                name = f"{prefix}{fam}{inv_suffix}{suffix}"
                call = dp_call(kernel, "Double(self)", qualifier, inverter, ar, ignore)
                out.append(f"    @inlinable func {name}(_ configuration: DimensConfiguration) -> Double {{")
                out.append(f"        {call}")
                out.append("    }")
                if inv_suffix == "":
                    out.append(f"    @inlinable func {name}Px(_ configuration: DimensConfiguration) -> Double {{")
                    out.append(f"        {call} * configuration.displayScale")
                    out.append("    }")


def gen_sp_members(prefix, kernel, sp_kernel, out):
    for fam, qualifier, font_scale, invs in SP_FAMILIES:
        for inv_suffix, inverter in invs:
            for suffix, ar, ignore in FLAGS:
                name = f"{prefix}{fam}{inv_suffix}{suffix}"
                call = sp_call(kernel, "Double(self)", qualifier, inverter, ar, ignore, font_scale, sp_kernel)
                out.append(f"    @inlinable func {name}(_ configuration: DimensConfiguration) -> Double {{")
                out.append(f"        {call}")
                out.append("    }")
                out.append(f"    @inlinable func {name}Px(_ configuration: DimensConfiguration) -> Double {{")
                out.append(f"        {call} * configuration.displayScale")
                out.append("    }")


def gen_ei_members(prefix, kernel, sp_kernel, out):
    for fam, qualifier in EI_FAMILIES:
        for suffix, ar, ignore in FLAGS:
            name = f"{prefix}{fam}{suffix}"
            if sp_kernel is not None:
                call = (f"AppDimens.{sp_kernel}(Double(self), configuration: configuration, "
                        f"qualifier: .{qualifier}, fontScale: false, "
                        f"ignoreMultiWindows: {str(ignore).lower()}, applyAspectRatio: {str(ar).lower()})")
            else:
                call = dp_call(kernel, "Double(self)", qualifier, "default", ar, ignore)
            out.append(f"    @inlinable func {name}(_ configuration: DimensConfiguration) -> Double {{")
            out.append(f"        {call} * configuration.displayScale")
            out.append("    }")


def gen_branch_members(prefix, kernel, sp_kernel, out):
    for fam, qualifier, is_sp in BRANCH_FAMILIES:
        for kind in ["Rotate", "Mode", "Qualifier", "Screen"]:
            for use_px in (False, True):
                name = f"{prefix}{fam}{kind}{'Px' if use_px else ''}"
                params = {"Rotate": "_ rotateValue: Double, orientation: Orientation = .landscape",
                          "Mode": "_ modeValue: Double, mode: UiModeType",
                          "Qualifier": "_ qualifiedValue: Double, qualifier: DpQualifier, minimum: Double, finalQualifier: DpQualifier = .smallWidth",
                          "Screen": "_ screenValue: Double, mode: UiModeType, qualifier: DpQualifier, minimum: Double, finalQualifier: DpQualifier = .smallWidth"}[kind]
                out.append(f"    @inlinable func {name}({params}, _ configuration: DimensConfiguration) -> Double {{")
                if kind == "Rotate":
                    sel = "configuration.orientation == orientation ? rotateValue : Double(self)"
                elif kind == "Mode":
                    sel = "configuration.uiMode == mode ? modeValue : Double(self)"
                elif kind == "Qualifier":
                    sel = "configuration.dimension(qualifier) >= minimum ? qualifiedValue : Double(self)"
                else:
                    sel = "(configuration.uiMode == mode && configuration.dimension(qualifier) >= minimum) ? screenValue : Double(self)"
                tail = " * configuration.displayScale" if use_px else ""
                branch_qualifier = qualifier if kind in ("Rotate", "Mode") else "finalQualifier"
                if is_sp:
                    call = sp_call(kernel, "selected", branch_qualifier, "default", False, False, True, sp_kernel)
                else:
                    call = dp_call(kernel, "selected", branch_qualifier, "default", False, False)
                out.append(f"        let selected = {sel}")
                out.append(f"        return {call.replace('.finalQualifier', 'finalQualifier')}{tail}")
                out.append("    }")


def generate(prefix, kernel, sp_kernel, module_dir, doc):
    header = ["// Generated by scripts/generate_catalogs.py — do not edit.",
              f"// {doc}"]
    if prefix:
        header += ["@_exported import AppDimens"]
    out = header + ["import Foundation", ""]
    for rcvr in ("public extension BinaryInteger {", "public extension BinaryFloatingPoint {"):
        out.append(rcvr)
        gen_dp_members(prefix, kernel, out)
        gen_sp_members(prefix, kernel, sp_kernel, out)
        gen_ei_members(prefix, kernel, sp_kernel, out)
        gen_branch_members(prefix, kernel, sp_kernel, out)
        out.append("}")
    if prefix:
        path = os.path.join(ROOT, "Sources", module_dir, "Catalog.swift")
    else:
        path = os.path.join(ROOT, "Sources", module_dir, "CoreCatalog.swift")
    with open(path, "w") as f:
        f.write("\n".join(out) + "\n")
    print(f"wrote {path} ({len(out)} lines)")


SATELLITES = [
    ("p", "percentDp", "AppDimensPercent", "percent satellite — `p*` catalog"),
    ("pw", "powerDp", "AppDimensPower", "power satellite — `pw*` catalog"),
    ("f", "fluidDp", "AppDimensFluid", "fluid satellite — `f*` catalog"),
    ("a", "autoDp", "AppDimensAuto", "auto satellite — `a*` catalog"),
    ("d", "densityDp", "AppDimensDensity", "density satellite — `d*` catalog"),
    ("dg", "diagonalDp", "AppDimensDiagonal", "diagonal satellite — `dg*` catalog"),
    ("fl", "fillDp", "AppDimensFill", "fill satellite — `fl*` catalog"),
    ("ft", "fitDp", "AppDimensFit", "fit satellite — `ft*` catalog"),
    ("i", "interpolatedDp", "AppDimensInterpolated", "interpolated satellite — `i*` catalog"),
    ("log", "logarithmicDp", "AppDimensLogarithmic", "logarithmic satellite — `log*` catalog"),
    ("pr", "perimeterDp", "AppDimensPerimeter", "perimeter satellite — `pr*` catalog"),
]

if __name__ == "__main__":
    generate("", "scaledDp", "scaledSp", "AppDimens",
             "Core scaled catalog — Android-familiar `sdp`/`ssp` naming (3.1.7 formulas).")
    for prefix, kernel, module, doc in SATELLITES:
        generate(prefix, kernel, None, module, doc)