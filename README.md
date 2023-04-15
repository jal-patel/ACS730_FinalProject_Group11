


# ACS730_FinalProject_Group11

**Team 11**
- Jal Patel @jal-patel
- Mithul @mitul000
- Damanpreet Singh @Damanpreet7291
- Vishal @veshal73
- Brahmjot Singh @Brahmjot09

***Final Architecture***
![WhatsApp Image 2023-04-14 at 23 06 14](https://user-images.githubusercontent.com/40731777/232180119-0547f5a6-5770-4746-9867-6bc148e9ca6a.jpg)

This environment contains:
-	A basic VPC network
-	A network gateway
-	An internet gateway
-	A security group that allows HTTP & SSH
-	A private S3 bucket
-	Two availability zones under same VPC network
-	Two public subnets
-	Two private subnets
-	One Application Load Balancer

From the diagram above, we can see that it has 3 availability zones. under each availability zone, it contains 3 public subnets & 3 private subnets. first subnet comprises One bastion host. Another public subnet is connected to a network gateway and third public subnet doesn't have any hosts running. Additionally, All the public subnets are connected to Application Load Balancer.
Rest of the private subnets are used to host our web servers. Furthermore, we have stored some pictures in our S3 storage bucket which can be fetched while our web server is running successfully. And lastly, We will have to define some Identity & Access Management roles assigned to our EC2 instance.

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

### Use of Load-Balancer
___
> Since we are using the load balancer, we will check that even after if we terminate any of the instance out of the multiple instances we created, the load will shift to the another remaining instances and website will work flawlessly.
So now we have terminated one of the instances and then open the IP of another instance in web browser and we are able to see the web page with the group member names and images uploaded to the s3 bucket.

***You can also access submission video by cicking on this link: [ ACS Project Video Submission Link ](https://seneca-my.sharepoint.com/:v:/r/personal/vssahoo_myseneca_ca/Documents/Recording-20230414_200803.webm?csf=1&web=1&e=2lVLdX)***

> Thanks
___
