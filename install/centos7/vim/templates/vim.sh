rm ~/.vim.old
mv -fb ~/.vim ~/.vimrc.old
mv -fb ~/.vimrc ~/.vimrc.old
git clone git://github.com/humiaozuzu/dot-vimrc.git ~/.vim
ln -s ~/.vim/vimrc ~/.vimrc
git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
#:BundleInstall


