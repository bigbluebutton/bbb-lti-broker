ssh-keygen -t rsa -b 4096 -m PEM -f .ssh/id_rsa

# copy pem into public key field on platform
cd .ssh/ && openssl rsa -in id_rsa -pubout -outform PEM -out pem