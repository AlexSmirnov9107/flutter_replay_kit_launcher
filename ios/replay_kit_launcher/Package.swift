// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import PackageDescription

let package = Package(
  name: "replay_kit_launcher",
  platforms: [
    .iOS("12.0")
  ],
  products: [
    .library(name: "replay-kit-launcher", targets: ["replay_kit_launcher"])
  ],
  dependencies: [],
  targets: [
    .target(
      name: "replay_kit_launcher",
      dependencies: [],
      resources: []
    )
  ]
)
