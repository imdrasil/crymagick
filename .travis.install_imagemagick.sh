set -exo pipefail

sudo apt-get remove imagemagick && sudo apt-get autoremove

sudo apt-get install build-essential
sudo apt-get build-dep imagemagick -y

wget "http://www.imagemagick.org/download/ImageMagick.tar.gz"
mkdir ImageMagick
tar xzvf ImageMagick.tar.gz -C ./ImageMagick

cd ImageMagick/*/
./configure

make

sudo make install

sudo ldconfig /user/local/lib

convert --version
