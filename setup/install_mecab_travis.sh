#!/usr/bin/env bash

wget -O mecab-0.996.tar.gz "https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7cENtOXlicTFaRUE"
tar zxfv mecab-0.996.tar.gz
cd mecab-0.996
./configure --prefix=/usr/local --enable-utf8-only
make && make check && sudo make install
sudo ldconfig

wget -O mecab-ipadic-2.7.0-20070801.tar.gz "https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7MWVlSDBCSXZMTXM"
tar zxfv mecab-ipadic-2.7.0-20070801.tar.gz
cd mecab-ipadic-2.7.0-20070801
./configure --prefix=/usr/local --with-mecab-config=/usr/local/bin/mecab-config --with-charset=utf8
make && sudo make install
sudo ldconfig