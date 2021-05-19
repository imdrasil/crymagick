set -exo pipefail

sudo apt-get remove imagemagick && sudo apt-get autoremove

sudo apt-get install build-essential
sudo apt-get build-dep imagemagick -y

im_version='7.0.11-13'

wget "http://www.imagemagick.org/download/ImageMagick-$im_version.tar.gz"
tar xzvf "ImageMagick-$im_version.tar.gz"

cd "ImageMagick-$im_version/"
./configure

make

sudo make install

sudo ldconfig /user/local/lib

convert --version
