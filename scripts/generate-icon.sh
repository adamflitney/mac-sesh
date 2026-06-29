#!/usr/bin/env bash
# Generates Resources/AppIcon.icns using AppKit.
# Requires macOS with Xcode command-line tools.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ICONSET="${REPO_ROOT}/AppIcon.iconset"

mkdir -p "${ICONSET}"

generate_png() {
    local size=$1
    local output=$2
    swift - "${size}" "${output}" <<'SWIFT'
import AppKit

let size = Int(CommandLine.arguments[1])!
let output = CommandLine.arguments[2]
let s = CGFloat(size)

let canvas = NSSize(width: s, height: s)
let image = NSImage(size: canvas)
image.lockFocus()

let ctx = NSGraphicsContext.current!.cgContext

// Dark navy rounded-rect background
let radius = s * 0.22
let rect = CGRect(x: 0, y: 0, width: s, height: s)
let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
ctx.addPath(path)
ctx.setFillColor(CGColor(red: 0.08, green: 0.08, blue: 0.16, alpha: 1.0))
ctx.fillPath()

let sectionGap = s * 0.04
let colBar = s * 0.16    // thicker bars for M columns
let rowBar = s * 0.10    // thinner bars for S rows
let colGapY = s * 0.035  // vertical gap between rows
let barRadius = colBar * 0.14

let totalBarSpan = colBar * 3 + s * 0.06 * 2  // width: thicker bars, tighter gaps
let colGapX = (totalBarSpan - colBar * 3) / 2  // gap between columns
let sectionH = rowBar * 3 + colGapY * 2        // height of each section (equal for M and S)

// Centre both sections in the canvas
let startX = (s - totalBarSpan) / 2
let startY = (s - (sectionH * 2 + sectionGap)) / 2

let colColor = CGColor(red: 0.25, green: 0.75, blue: 1.0, alpha: 1.0)
let rowColor = CGColor(red: 0.35, green: 0.50, blue: 0.62, alpha: 1.0)

// S: 3 horizontal rows (bottom section)
ctx.setFillColor(rowColor)
for j in 0..<3 {
    let y = startY + CGFloat(j) * (rowBar + colGapY)
    let rowPath = CGPath(roundedRect: CGRect(x: startX, y: y, width: totalBarSpan, height: rowBar),
                         cornerWidth: barRadius, cornerHeight: barRadius, transform: nil)
    ctx.addPath(rowPath)
    ctx.fillPath()
}

// M: 3 vertical columns (top section)
let mStartY = startY + sectionH + sectionGap
ctx.setFillColor(colColor)
for i in 0..<3 {
    let x = startX + CGFloat(i) * (colBar + colGapX)
    let colPath = CGPath(roundedRect: CGRect(x: x, y: mStartY, width: colBar, height: sectionH),
                         cornerWidth: barRadius, cornerHeight: barRadius, transform: nil)
    ctx.addPath(colPath)
    ctx.fillPath()
}

image.unlockFocus()

let rep = NSBitmapImageRep(cgImage: image.cgImage(forProposedRect: nil, context: nil, hints: nil)!)
let data = rep.representation(using: .png, properties: [:])!
try! data.write(to: URL(fileURLWithPath: output))
SWIFT
}

echo "→ Generating icon PNGs…"
generate_png 16   "${ICONSET}/icon_16x16.png"
generate_png 32   "${ICONSET}/icon_16x16@2x.png"
generate_png 32   "${ICONSET}/icon_32x32.png"
generate_png 64   "${ICONSET}/icon_32x32@2x.png"
generate_png 128  "${ICONSET}/icon_128x128.png"
generate_png 256  "${ICONSET}/icon_128x128@2x.png"
generate_png 256  "${ICONSET}/icon_256x256.png"
generate_png 512  "${ICONSET}/icon_256x256@2x.png"
generate_png 512  "${ICONSET}/icon_512x512.png"
generate_png 1024 "${ICONSET}/icon_512x512@2x.png"

echo "→ Converting to ICNS…"
iconutil --convert icns --output "${REPO_ROOT}/Resources/AppIcon.icns" "${ICONSET}"

rm -rf "${ICONSET}"

echo "✓ Resources/AppIcon.icns"
