# 本地中文字体

- 文件：`NotoSansCJKsc-Regular.otf`
- 用途：作为项目默认中文 UI 字体，确保导出到 Web 时不会因为宿主环境缺字而乱码。
- 来源：`notofonts/noto-cjk`
- 下载地址：`https://github.com/notofonts/noto-cjk`

说明：

- 当前项目中的 `scripts/hud.gd` 会默认使用这份字体渲染所有运行时创建的标签。
- 如果后续要替换字体，优先保留可商用、可再分发的开源中文字体，并继续使用本地打包方式。
