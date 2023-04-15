# ACS730_FinalProject_Group11

> ##  Step To Deploy:
1. Open Terminal in __*ACS730_FinalProject_Group11/project/Development/network/*__ folder.
2. Create alias ``` alias tf=terraform ```
3. Do terraform initialization ``` tf init```
4. Do terraform format ``` tf fmt ```
5. Do terraform validate ``` tf validate ```
6. Do terrafrom plan ``` tf plan ```
7. Now we will create 2 ssh keys that we have used in this project:
```
ssh-keygen -t rsa -f "access"
ssh-keygen -t rsa -f "bastion_key"
```
8. Now we will import the above ssh keys to aws console by coping .pub key and importing to aws console "_**key-pairs**_".
9. After importing run following command:
```
 tf apply --auto-approve 
```
10. After deployment is completed successfully we can see newly created instances on aws console and verify by opening public ip of newly created instances.
11. When we open public ip we see customized web page with 3 photos also and if we see our bucket in S3 on aws console we can verify that our photos have been uploaded on S3 bucket also.
