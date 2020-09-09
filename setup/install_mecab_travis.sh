#!/usr/bin/env bash

set -ex

cur=$(pwd)
dir=${cur}/.mecab
PATH=$PATH:${dir}/bin

if which mecab >/dev/null 2>&1; then
  echo "mecab: $(which mecab)"
  echo "mecab-config: $(which mecab-config)"
  echo "mecab libs: $(mecab-config --libs)"
  exit
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

cd $cur
