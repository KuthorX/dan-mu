# 本地中文字体

| 文件 | 用途 | 来源 | 许可 |
| --- | --- | --- | --- |
| `NotoSansCJKsc-Regular-subset.otf` | 默认 UI 字体与所有 Label 的回退字体 | [notofonts/noto-cjk](https://github.com/notofonts/noto-cjk) | `licenses/NotoSansCJK-OFL.txt` |
| `NotoSerifSC-Bold-subset.ttf` | 正文与数字 | Google Fonts `notoserifsc` | `licenses/NotoSerifSC-OFL.txt` |
| `MaShanZheng-subset.ttf` | 书法标题 | Google Fonts `mashanzheng` | `licenses/MaShanZheng-OFL.txt` |

三份字体都只保留 `i18n/translations.csv`、`scripts/*.gd`、`scenes/*.tscn` 中出现的字符和可打印 ASCII，
以减小导出包体积（完整的 Noto Sans CJK SC 有 16 MB，子集约 260 KB）。

新增文案后重新生成：

```
https_proxy=http://127.0.0.1:7890 python3 tools/art/subset_fonts.py
```

脚本最后会打印子集字体缺失的字形数，应为 0。
