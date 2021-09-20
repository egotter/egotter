```sh
cd assets
zip assets.zip ./assets/* -x ./assets/*.md
aws lambda publish-layer-version --layer-name [NAME] --zip-file fileb://assets.zip --compatible-runtimes ruby2.7
```
