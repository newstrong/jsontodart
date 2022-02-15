1、渲染引擎 Canvaskit 下载太慢，这个Canvaskit是从https://unpkg.com去加载的，国内访问这个地址耗时较长，
通过镜像去加载能优化这个时间。 我这边从网上找到的镜像地址 https://cdn.jsdelivr.net/npm
（ps：目前我测下来这个镜像源应该是加载耗时最短的）。

命令:flutter build web --dart-define=FLUTTER_WEB_CANVASKIT_URL=https://cdn.jsdelivr.net/npm/canvaskit-wasm@0.28.1/bin/




