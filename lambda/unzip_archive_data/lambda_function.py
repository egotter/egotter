import os
import urllib.parse
import zipfile
import re
import shutil
import boto3
from botocore.config import Config

s3 = boto3.client('s3', config=Config(region_name='ap-northeast-1'))


# Deploy
# cd lambda/unzip_archive_data
# zip function.zip lambda_function.py
# aws lambda update-function-code --function-name [NAME] --zip-file fileb://function.zip
# aws lambda publish-version --function-name [NAME]
# rm function.zip
#
# Show code diffs
# aws lambda get-function --function-name [NAME] | jq .Code.Location -r | xargs curl -s -o code.zip && unzip -p code.zip lambda_function.py | colordiff -u lambda_function.py -
# rm code.zip
def lambda_handler(event, context):
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')

    if not re.match('^[0-9a-zA-Z_-]+$', key):
        raise Exception(f'Invalid key value={key}')

    response = s3.head_object(Bucket=bucket, Key=key)
    meta_filename = response['ResponseMetadata']['HTTPHeaders']['x-amz-meta-filename']
    meta_filesize = response['ResponseMetadata']['HTTPHeaders']['x-amz-meta-filesize']

    if not re.match('^twitter-[0-9a-zA-Z-]+\\.zip$', meta_filename):
        raise Exception(f'Invalid filename value={meta_filename} key={key}')

    # 30 GB
    if int(meta_filesize) > 30000000000:
        raise Exception(f'Invalid filesize value={meta_filesize} key={key}')

    rootdir = '/mnt/data/'
    dirname = rootdir + key + '/'

    if os.path.exists(dirname):
        shutil.rmtree(dirname)
    os.mkdir(dirname)

    archive_file = dirname + meta_filename
    s3.download_file(Bucket=bucket, Key=key, Filename=archive_file)
    extract_file(archive_file, dirname)


def extract_file(archive_file, outdir):
    with zipfile.ZipFile(archive_file) as existing_zip:
        for member in existing_zip.namelist():
            name = os.path.basename(member)

            if not name:
                continue

            if not re.match('^tweet.*\\.js$', name):
                continue

            source = existing_zip.open(member)
            target = open(os.path.join(outdir, name), 'wb')

            with source, target:
                shutil.copyfileobj(source, target)
