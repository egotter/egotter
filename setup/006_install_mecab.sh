#!/bin/bash

HOME="/home/ec2-user"
USER="ec2-user"

sudo -u ${USER}
cd ${HOME}

wget -O mecab-0.996.tar.gz "https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7cENtOXlicTFaRUE"
tar zxfv mecab-0.996.tar.gz
cd mecab-0.996
./configure --enable-utf8-only
make
make check
sudo make install
sudo ldconfig

cd ${HOME}

wget -O mecab-ipadic-2.7.0-20070801.tar.gz "https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7MWVlSDBCSXZMTXM"
tar zxfv mecab-ipadic-2.7.0-20070801.tar.gz
cd mecab-ipadic-2.7.0-20070801
./configure --with-charset=utf8
make
sudo make install
sudo ldconfig

cd ${HOME}
rm -rf mecab-0.996 mecab-ipadic-2.7.0-20070801
