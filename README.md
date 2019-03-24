# s3Upload.sh :floppy_disk:
---
s3Upload.sh is a bash script that you can use to upload a file to your AWS S3 bucket. Its scripted in pure bash and uses nothing but curl and openssl to sign and upload your request. This script was made to learn more about AWS V4 signature signing process and to get around situations where you can't install additional packages on a running system due to compliance or security reasons.

#### Example usage:
```bash
./s3Upload.sh -b <bucket name> -l <file path without '/' at end> -f <file name> -r <region>

./s3Upload.sh -b bucketofchickenwings -l /home/user -f dummyfile.txt -r us-east-1
```

Feel free to modify this script and use as you please. The script can be refactored/cleaned up. I was planning on adding an option to specify a folder within an S3 bucket and was also going to put everything into their own function. However, at this time the script itself does not serve me a purpose. It was done for education reasons. :)

#### Huge shoutouts to the following resources:
 - [Amazon S3 REST API with curl - Łukasz Adamczak](https://czak.pl/2015/09/15/s3-rest-api-with-curl.html)
 - [Signature Version 4 Signing Process - Amazon Web Services](https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html)
