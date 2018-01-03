H5ai是一款功能强大 php 文件目录列表程序，由德国开发者 Lars Jung 主导开发，它提供多种文件目录列表呈现方式,
支持多种主流 Web 服务器，例如 Nginx、Apache、Cherokee、Lighttpd 等，支持多国语言，可以使用本程序在线预览文本、图片、音频、视频等。

- h5ai支持多语言,但默认显示的是英文,可修改配置文件 _h5ai/private/conf/options.json 
```bash
    "l10n": {
        "enabled": true,
        "lang": "en",
        "useBrowserLang": true
    },
```
修改 lang 的值 en 为 zh-cn 即可 默认显示为中文

```bash
    "l10n": {
        "enabled": true,
        "lang": "zh-cn",
        "useBrowserLang": true
    },

```
- 开启搜索功能 (enabled值：false 改为 true)
```bash
    "search": {
        "enabled": false,
        "advanced": true,
        "debounceTime": 300,
        "ignorecase": true
    },
```
修改为

```bash
    "search": {
        "enabled": true,
        "advanced": true,
        "debounceTime": 300,
        "ignorecase": true
    },
```
- 开启二维码功能 false 改为 true
```bash
    "info": {
        "enabled": false,
        "show": false,
        "qrcode": true,
        "qrFill": "#999",
        "qrBack": "#fff"
    },

```
修改为
```bash
    "info": {
        "enabled": true,
        "show": true,
        "qrcode": true,
        "qrFill": "#999",
        "qrBack": "#fff"
    },

```

- 官方介绍

   https://larsjung.de/h5ai/
   
- 官方稳定版本下载

   https://release.larsjung.de/h5ai/
