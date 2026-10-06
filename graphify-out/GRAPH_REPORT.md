# Graph Report - caphe  (2026-10-06)

## Corpus Check
- 97 files · ~84,490 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 52 file(s) not represented in the graph (top: (none) 8, .xcconfig 8, .xml 7)

## Summary
- 639 nodes · 796 edges · 22 communities (14 shown, 8 thin omitted)
- Extraction: 93% EXTRACTED · 7% INFERRED · 0% AMBIGUOUS · INFERRED: 56 edges (avg confidence: 0.87)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Flutter UI Core
- Windows Platform Bridge
- iOS/macOS Platform Bridge
- Android App Icons
- Linux Platform Bridge
- Project Config & Assets
- Screen & State Management
- Coffee Menu Images
- Windows Flutter Engine
- Web Manifest & PWA
- App Widgets & Background
- Windows Plugin Registry
- Order Flow & Navigation
- Custom Painters
- iOS Launch Images
- Supabase Edge Functions
- Android Main Activity

## God Nodes (most connected - your core abstractions)
1. `__` - 347 edges
2. `Default Flutter app icon` - 28 edges
3. `Win32Window` - 21 edges
4. `Quan Nha logo (Ca phe Gia dinh) - house, steaming cup, coffee bean badge` - 17 edges
5. `Menu image style: flat vector drink on wooden table, cream backdrop, coffee beans, logo badge` - 16 edges
6. `FlutterWindow` - 10 edges
7. `caphe Package (pubspec)` - 10 edges
8. `_MyApplication` - 7 edges
9. `WindowClassRegistrar` - 7 edges
10. `flutter Interface Library (Windows DLL)` - 7 edges

## Surprising Connections (you probably didn't know these)
- `APPLY_STANDARD_SETTINGS (Linux, C++14 -Wall -Werror)` --semantically_similar_to--> `APPLY_STANDARD_SETTINGS (Windows, C++17 /W4 /WX)`  [INFERRED] [semantically similar]
  linux/CMakeLists.txt → windows/CMakeLists.txt
- `Linux Install Bundle` --semantically_similar_to--> `Windows Install Bundle`  [INFERRED] [semantically similar]
  linux/CMakeLists.txt → windows/CMakeLists.txt
- `flutter Interface Library (Linux GTK)` --semantically_similar_to--> `flutter Interface Library (Windows DLL)`  [INFERRED] [semantically similar]
  linux/flutter/CMakeLists.txt → windows/flutter/CMakeLists.txt
- `iOS Launch Screen Assets` --conceptually_related_to--> `caphe Package (pubspec)`  [INFERRED]
  ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md → pubspec.yaml
- `Linux Build Project (caphe, com.example.caphe)` --conceptually_related_to--> `caphe Package (pubspec)`  [INFERRED]
  linux/CMakeLists.txt → pubspec.yaml

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Linux Desktop Build Pipeline** — linux_cmakelists_runner_project, linux_flutter_cmakelists_flutter, linux_flutter_cmakelists_flutter_assemble, linux_runner_cmakelists_caphe_executable, linux_cmakelists_install_bundle [EXTRACTED 1.00]
- **caphe App Runtime Dependencies (backend, storage, fonts)** — pubspec_caphe, pubspec_supabase_flutter, pubspec_shared_preferences, pubspec_google_fonts [INFERRED 0.85]
- **Windows Desktop Build Pipeline** — windows_cmakelists_caphe_project, windows_flutter_cmakelists_flutter, windows_flutter_cmakelists_flutter_wrapper_app, windows_flutter_cmakelists_flutter_assemble, windows_runner_cmakelists_caphe_executable [EXTRACTED 1.00]
- **Default Flutter icon across Android/iOS/macOS resolutions** — android_app_src_main_res_mipmap_hdpi_ic_launcher_ic_launcher, android_app_src_main_res_mipmap_mdpi_ic_launcher_ic_launcher, android_app_src_main_res_mipmap_xhdpi_ic_launcher_ic_launcher, android_app_src_main_res_mipmap_xxhdpi_ic_launcher_ic_launcher, android_app_src_main_res_mipmap_xxxhdpi_ic_launcher_ic_launcher, ios_runner_assets_xcassets_appicon_appiconset_icon_app_1024x1024_1x_icon_app_1024x1024_1x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_20x20_1x_icon_app_20x20_1x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_20x20_2x_icon_app_20x20_2x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_20x20_3x_icon_app_20x20_3x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_29x29_1x_icon_app_29x29_1x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_29x29_2x_icon_app_29x29_2x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_29x29_3x_icon_app_29x29_3x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_40x40_1x_icon_app_40x40_1x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_40x40_2x_icon_app_40x40_2x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_40x40_3x_icon_app_40x40_3x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_60x60_2x_icon_app_60x60_2x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_60x60_3x_icon_app_60x60_3x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_76x76_1x_icon_app_76x76_1x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_76x76_2x_icon_app_76x76_2x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_83_5x83_5_2x_icon_app_83_5x83_5_2x, macos_runner_assets_xcassets_appicon_appiconset_app_icon_1024_app_icon_1024, macos_runner_assets_xcassets_appicon_appiconset_app_icon_128_app_icon_128, macos_runner_assets_xcassets_appicon_appiconset_app_icon_16_app_icon_16, macos_runner_assets_xcassets_appicon_appiconset_app_icon_256_app_icon_256, macos_runner_assets_xcassets_appicon_appiconset_app_icon_32_app_icon_32, macos_runner_assets_xcassets_appicon_appiconset_app_icon_512_app_icon_512, macos_runner_assets_xcassets_appicon_appiconset_app_icon_64_app_icon_64 [EXTRACTED 1.00]
- **iOS LaunchImage @1x/@2x/@3x placeholders** — ios_runner_assets_xcassets_launchimage_imageset_launchimage_launchimage, ios_runner_assets_xcassets_launchimage_imageset_launchimage_2x_launchimage_2x, ios_runner_assets_xcassets_launchimage_imageset_launchimage_3x_launchimage_3x [EXTRACTED 1.00]
- **Quan Nha brand web favicon and PWA icon set** — web_favicon_favicon, web_icons_icon_192_icon_192, web_icons_icon_512_icon_512, web_icons_icon_maskable_192_icon_maskable_192, web_icons_icon_maskable_512_icon_maskable_512 [EXTRACTED 1.00]
- **Coffee menu items** — web_images_menu_cf_cappuccino_cappuccino, web_images_menu_cf_den_ca_phe_den_da, web_images_menu_cf_espresso_espresso, web_images_menu_cf_muoi_ca_phe_muoi, web_images_menu_cf_sua_ca_phe_sua_da [INFERRED 0.95]
- **Fruit juices, smoothies and yogurt items** — web_images_menu_ep_cam_nuoc_ep_cam, web_images_menu_ep_thom_nuoc_ep_thom, web_images_menu_st_bo_sinh_to_bo, web_images_menu_st_dau_sinh_to_dau, web_images_menu_sc_vietquat_sua_chua_viet_quat [INFERRED 0.85]
- **Tea and milk tea menu items** — web_images_menu_tra_dao_tra_dao_cam_sa, web_images_menu_tra_sua_tc_tra_sua_tran_chau, web_images_menu_tra_sua_thai_tra_sua_thai_xanh, web_images_menu_tra_vai_tra_vai, web_images_menu_matcha_latte_matcha_latte [INFERRED 0.85]

## Communities (22 total, 8 thin omitted)

### Community 0 - "Flutter UI Core"
Cohesion: 0.01
Nodes (278): __, accent, accentLight, _addButton, amount, AppColors, AppConfig, _appliedCode (+270 more)

### Community 1 - "Windows Platform Bridge"
Cohesion: 0.05
Nodes (20): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_, EnableFullDpiSupportIfAvailable(), Point, x, y (+12 more)

### Community 2 - "iOS/macOS Platform Bridge"
Cohesion: 0.06
Nodes (16): app_links, Cocoa, Flutter, FlutterMacOS, Foundation, AppDelegate, SceneDelegate, RunnerTests (+8 more)

### Community 3 - "Android App Icons"
Cohesion: 0.06
Nodes (34): Android launcher icon (hdpi), Android launcher icon (mdpi), Android launcher icon (xhdpi), Android launcher icon (xxhdpi), Android launcher icon (xxxhdpi), Default Flutter app icon, iOS Icon-App-1024x1024@1x, iOS Icon-App-20x20@1x (+26 more)

### Community 4 - "Linux Platform Bridge"
Cohesion: 0.08
Nodes (14): fl_register_plugins(), main(), first_frame_cb(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line() (+6 more)

### Community 5 - "Project Config & Assets"
Cohesion: 0.09
Nodes (28): Flutter Lints Analysis Config, iOS Launch Screen Assets, APPLY_STANDARD_SETTINGS (Linux, C++14 -Wall -Werror), Linux Install Bundle, Linux Build Project (caphe, com.example.caphe), flutter Interface Library (Linux GTK), flutter_assemble (Linux tool_backend.sh), list_prepend (+20 more)

### Community 6 - "Screen & State Management"
Cohesion: 0.11
Nodes (22): AdminDashboardScreen, _AdminDashboardScreenState, BaristaScreen, _BaristaScreenState, CartBottomSheet, _CartBottomSheetState, CustomerMenuScreen, _CustomerMenuScreenState (+14 more)

### Community 7 - "Coffee Menu Images"
Cohesion: 0.20
Nodes (25): Cappuccino (hot, latte-art heart, ceramic cup), Ca phe den da (iced black coffee), Coffee drinks category (cf_), Menu image style: flat vector drink on wooden table, cream backdrop, coffee beans, logo badge, Espresso (hot, small ceramic cup), Ca phe muoi (salt coffee with cream foam), Ca phe sua da (iced milk coffee, condensed milk layer), Cookie da xay (cookies and cream ice blended) (+17 more)

### Community 8 - "Windows Flutter Engine"
Cohesion: 0.12
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 9 - "Web Manifest & PWA"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 10 - "App Widgets & Background"
Cohesion: 0.25
Nodes (7): AppBackground, BillView, BrandBadge, CoffeeShopApp, _MascotFace, QtyStepper, TransferQrDialog

### Community 12 - "Order Flow & Navigation"
Cohesion: 0.33
Nodes (5): _afterOrderPlaced, build, initState, _openStaffMenu, _selectTable

### Community 13 - "Custom Painters"
Cohesion: 0.50
Nodes (3): _BeanPatternPainter, _MascotPainter, RevenueChartPainter

### Community 14 - "iOS Launch Images"
Cohesion: 0.50
Nodes (4): iOS blank launch image placeholder, iOS LaunchImage@2x, iOS LaunchImage@3x, iOS LaunchImage

## Knowledge Gaps
- **349 isolated node(s):** `AppConfig`, `AppColors`, `MenuItem`, `Topping`, `CartItem` (+344 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 441 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **8 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `__` connect `Flutter UI Core` to `App Widgets & Background`, `Order Flow & Navigation`, `Custom Painters`, `Screen & State Management`?**
  _High betweenness centrality (0.302) - this node is a cross-community bridge._
- **What connects `AppConfig`, `AppColors`, `MenuItem` to the rest of the system?**
  _349 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Flutter UI Core` be split into smaller, more focused modules?**
  _Cohesion score 0.006472491909385114 - nodes in this community are weakly interconnected._
- **Why does `Win32Window` connect `Windows Platform Bridge` to `Windows Flutter Engine`?**
  _High betweenness centrality (0.009) - this node is a cross-community bridge._
- **Should `Windows Platform Bridge` be split into smaller, more focused modules?**
  _Cohesion score 0.05268065268065268 - nodes in this community are weakly interconnected._
- **Why does `FlutterWindow` connect `Windows Platform Bridge` to `Windows Flutter Engine`?**
  _High betweenness centrality (0.006) - this node is a cross-community bridge._
- **Should `iOS/macOS Platform Bridge` be split into smaller, more focused modules?**
  _Cohesion score 0.05807200929152149 - nodes in this community are weakly interconnected._