#Downloading scommand to run the loadtest from cloudtest
cloudtest_url=https://ec2-18-235-65-145.compute-1.amazonaws.com/concerto
sc_zip_url=$cloudtest_url/downloads/scommand/scommand.zip
wget --no-check-certificate --no-verbose -O scommand.zip $sc_zip_url
unzip ./scommand.zip


