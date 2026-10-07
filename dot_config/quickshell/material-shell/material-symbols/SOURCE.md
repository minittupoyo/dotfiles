Google Material Symbols Outlined
Source: https://github.com/google/material-design-icons/tree/737e3324305806514d7909874fa1818ae1808232/symbols/web
FILL 0 / weight 400 / grade 0 / optical size 24.
SVG root fill adapted to the bar theme. Apache-2.0; see LICENSE.

SVGのfillは白いマスクに置換し、MaterialIcon.qmlでThemeの色へ動的着色する。追加SVGもrootに`fill="#ffffff"`を指定する。黒いpathのままだとMultiEffectのcolorizationで色が反映されない。
同梱するBluetooth・調整・有線ネットワークのアイコンも同じリビジョンの `symbols/web/{name}/materialsymbolsoutlined/{name}_24px.svg` から取得し、それぞれ `bluetooth.svg`、`tune.svg`、`settings_ethernet.svg` として使用。

フォルダーピッカーの `folder_open.svg` も同じリビジョンの `symbols/web/folder_open/materialsymbolsoutlined/folder_open_24px.svg` を使用し、root fillを白いマスクにしている。
