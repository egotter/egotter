#!/usr/bin/env bash

set -ex

if ! command -v mecab &>/dev/null; then
  echo "mecab found"
  exit
fi

cur=$(pwd)

dir=${pwd}/.mecab
if [ ! -d $dir ]; then
  mkdir $dir
fi
cd $dir

wget -O mecab-0.996.tar.gz "https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7cENtOXlicTFaRUE"
tar zxfv mecab-0.996.tar.gz
cd mecab-0.996
./configure --prefix=$dir --enable-utf8-only
make && make check && sudo make install
sudo ldconfig

wget -O mecab-ipadic-2.7.0-20070801.tar.gz "https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7MWVlSDBCSXZMTXM"
tar zxfv mecab-ipadic-2.7.0-20070801.tar.gz
cd mecab-ipadic-2.7.0-20070801
./configure --prefix=$dir --with-mecab-config=${dir}/bin/mecab-config --with-charset=utf8
make && sudo make install
sudo ldconfig

PATH=$PATH:${dir}/bin

cd $cur
