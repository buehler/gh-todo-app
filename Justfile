build_runner:
	dart run build_runner build

launcher_icons:
	dart run flutter_launcher_icons

deploy_web:
	flutter build web --release
	cp vercel.json build/web/vercel.json
	cp assets/legal/* build/web/
	vercel deploy --prod --cwd build/web/
