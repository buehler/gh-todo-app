# Changelog

## [1.2.0](https://github.com/buehler/gh-todo-app/compare/v1.1.0...v1.2.0) (2026-08-12)


### Features

* add changelog page to settings to see exact changes ([bd698ac](https://github.com/buehler/gh-todo-app/commit/bd698acb026198eb508501ba8b6d7d464512cb49))
* add project setting "issue query" that allows filtering for other issues ([59ac482](https://github.com/buehler/gh-todo-app/commit/59ac48201a4dfb050b09b7aff96c58f521d2f4a6))
* allow adding projects from other github users (direct access via username) ([6b89a7c](https://github.com/buehler/gh-todo-app/commit/6b89a7c2d9d0ccc891c96ed3eea8e297a85b07ea))
* allow hide and delete of comments inside issue details ([a01ed4f](https://github.com/buehler/gh-todo-app/commit/a01ed4fad05d91699860732317ec339b50aa93ca))
* **ios:** add better logging for diagnosis (no PII revealed) ([7e185e6](https://github.com/buehler/gh-todo-app/commit/7e185e6736a6b8d76e6ff59c3c7d87fa9249a908))
* **ios:** widget shows last updated timestamp ([0a81474](https://github.com/buehler/gh-todo-app/commit/0a8147489c96d6e7b7fbca4f35d765b9c5727757))
* use better project switcher ([f97ccd3](https://github.com/buehler/gh-todo-app/commit/f97ccd35f17882bc06e56a13abd407de23c2fac8))


### Bug Fixes

* also use cmd/ctrl enter in edit comment ([a7fd574](https://github.com/buehler/gh-todo-app/commit/a7fd574454959091b61aefdee36ffc8ed22ab6d2))
* cmd / ctrl enter also works in edit issue sheet ([0756313](https://github.com/buehler/gh-todo-app/commit/07563133ccd05c9baedf46bf11654bd77b95ae9d))
* **ios:** correctly use PAT in widgets after first unlock and migrate them ([1b0b337](https://github.com/buehler/gh-todo-app/commit/1b0b3379f460913135f9ab0dabcc0377f3434165))
* **ios:** dont show closed issues unlimited time ([6829f72](https://github.com/buehler/gh-todo-app/commit/6829f72a3fd0110adc6fe7b00d0ddc7332aa38c8))
* **ios:** remove icloud synchronizable tokens ([26fcefe](https://github.com/buehler/gh-todo-app/commit/26fcefe78f82b63b3da30ff0467630f6108fb6ce))
* **ios:** remove small widget because its useless ([632ddf7](https://github.com/buehler/gh-todo-app/commit/632ddf7adcacaa0929689622d0930ba66fea0a94))
* **ios:** widget shows owner in config instead of id ([e2bffb6](https://github.com/buehler/gh-todo-app/commit/e2bffb6c485525cf9236ebab9057b8ddc0b60af4))
* not clickable link in changelog ([9133764](https://github.com/buehler/gh-todo-app/commit/91337649724df42ba3cd143c32211b7a6ddc44a7))
* unfocus on successfull post comment in issue detail ([3eba935](https://github.com/buehler/gh-todo-app/commit/3eba9353fe8e86d33d7181f8d9954befe48e828b))
* use pat insert/update as password field (hidden values and triggers password autofill) ([a3cdd75](https://github.com/buehler/gh-todo-app/commit/a3cdd75fb93898911867bb5b91df910fd95638bd))

## [1.1.0](https://github.com/buehler/gh-todo-app/compare/v1.0.0...v1.1.0) (2026-07-23)


### Features

* add a boot screen and fix ios team ([ae0b972](https://github.com/buehler/gh-todo-app/commit/ae0b9722932d30fd3a5412fbeb173bd9de159a41))
* add ios widget for todos ([a68ac8f](https://github.com/buehler/gh-todo-app/commit/a68ac8f922deddbe4baac0d9e1bc8d1ff4f2d318))
* add list continuation for text fields (markdown) ([316fd2d](https://github.com/buehler/gh-todo-app/commit/316fd2dae470060ae600d93e494a1078c9ed8072))
* allow pressing of GH markdown checkboxes to toggle them ([23018a7](https://github.com/buehler/gh-todo-app/commit/23018a75b47636f7afeee978a08adf8986e90da3))


### Bug Fixes

* **ios:** ITSAppUsesNonExemptEncryption ([3f858f9](https://github.com/buehler/gh-todo-app/commit/3f858f958f1680b6d91bad0031d3606578318789))
* **ios:** widget deep links open correctly ([9738309](https://github.com/buehler/gh-todo-app/commit/97383094b78a09d21a1336cdc737bb609967633e))
* list completion not working in between lists ([6eeecac](https://github.com/buehler/gh-todo-app/commit/6eeecacad8ab54bd8243f7cd4fcb1318817f819d))
* make widget available in ios 26 ([3b0b06f](https://github.com/buehler/gh-todo-app/commit/3b0b06fd55c895410db553b8a46b2b20d9d52969))
* no navigation animations on wide screen issue navigation ([8e31a59](https://github.com/buehler/gh-todo-app/commit/8e31a59c102136bf6b666e45f7242b9fe9c83406))
* only use method channel for platforms that are implemented ([9b7d1e2](https://github.com/buehler/gh-todo-app/commit/9b7d1e20d6cb82326c9cb8be911da27e78881f4f))
* visual space for first element in checkbox list removed ([7986838](https://github.com/buehler/gh-todo-app/commit/7986838629599f3fceede8da7da7d594df65fd3e))
