
### This project aims to create a serverless portfolio website, with AWS.

<br>
<br>

<img src="resume-site/images/INFRA.png" alt="My Image" width="700"/>

<br>
<br>

### To create this website, I used:

#### AWS resources :
- IAM
- S3
- Lambda
- APIGateway
- DynamoDB
- ACM
- Route53
- Cloudfront

#### Programing Languages:
- Python
- Javascript

#### And
- PyCharm as IDE
- Git as VSC
- Terraform
- Linux
- Github actions



### BACKEND

Part of the challenge was to implement a function that counts the number of visitors on my website, and returns that number.
For that I used **Lambda** for the function,
**DynamoDB** to store the data and **APIGateway** to access that data from my website.


*
I wrote the function in **Python**. I imported the AWS SDK `boto3`, to access my table and update it
by adding 1 to my 'visitor' attribute, and then return a json response containing my visitor count: 

```py
import json
import boto3

dynamodb = boto3.resource('dynamodb', 'us-east-1')
table = dynamodb.Table('cloud-resume-challenge')


def visitors_count(event, context):
    response = table.update_item(Key={'ID': 'visitors'},
                                 AttributeUpdates={'visitors': {'Value': 1, 'Action': 'ADD'}},
                                 ReturnValues='UPDATED_NEW')

    body = {"visitors": str(response['Attributes']['visitors'])}

    return {
        "statusCode": 200,
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Content-Type": "application/json"
        },
        "body": json.dumps(body)
    }
```


I added some **Javascript** on my html index file, so that loading the page fetches the API,
which calls the function I just created, adds 1 to the count and return the updated count.
It looked like this :
```
<script>
        fetch('https://xf5z9o0wwh.execute-api.us-east-1.amazonaws.com/Prod/visitors_count')
            .then(response => response.json())
            .then((data) => {
                document.getElementById('visitors').innerText = data.visitors
            })
    </script>
```
I also wanted to display that count on the website, so I added in a paragraph:

```
Visitors : <span id="visitors" />
```
*


Everything got deployed without error! And when I visited my website,
the visitor count was displayed and updated on each refresh!

### CI/CD
My website was up and running, but everytime I brought changes to my files
I needed to manually use SAM and build and deploy...

To automate that process, I implemented some CI/CD, so each time I update my files and commit>push the S3 files get update
and the code is deployed.


First, I wanted my function to be tested before anything is deployed.
So I used `pytest` and `mock_dynamodb` from `moto` to mock a **DynamoDB** table for my test.
I kept, as the event parameter for my test function, the API event from the base
test_hello_world function that was created when I used `sam init`.
Then I created the test function.

This was the hardest part for me, as it was the first time using moto, and I was struggling with it.
The test function was trying to call my real table and I didn't know the mocked table needed to be exactly
identical to the real table to avoid that issue.
I fixed it by naming the table, the items and everything just like the real table's, and it worked!
I could locally pytest my function with success.

The final test looks like :

```py
import json
import boto3
import pytest
from moto import mock_dynamodb


# API event here

@mock_dynamodb
def test_visitors_count(apigw_event):
    from visitors_count import app
    table_name = 'cloud-resume-challenge'
    # Create mock DynamoDB table
    dynamodb = boto3.resource('dynamodb', 'us-east-1')
    table = dynamodb.create_table(
        TableName=table_name,
        KeySchema=[{'AttributeName': 'ID', 'KeyType': 'HASH'}],
        AttributeDefinitions=[{'AttributeName': 'ID', 'AttributeType': 'S'}],
        ProvisionedThroughput={'ReadCapacityUnits': 2, 'WriteCapacityUnits': 1}
    )

    ret = app.visitors_count(apigw_event, "")
    data = json.loads(ret["body"])

    assert ret["statusCode"] == 200
    assert data == {"visitors": "1"}
```
*
I implemented it to Github actions,
creating a ".github/workflows" directory and inside a yaml file to tell Github Actions what to do.

I wanted it to test my function everytime I push a commit. My AWS credentials were stored as secrets:
```yml
name: test build deploy
on: push

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Set up Python 3.8
      uses: actions/setup-python@v4
      with:
        python-version: "3.8"
    - run: pip install -r requirementsxx.txt
    - name: Test with pytest
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      run: pytest
```
Then, a `sam build` and `sam deploy` once the test is done and successful :

```yml
  build-and-deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: "3.9"
      - uses: aws-actions/setup-sam@v1
      - uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      - run: sam build
      - run: sam deploy --no-confirm-changeset --no-fail-on-empty-changeset
```
*
Finally, I also wanted my website files to be updated, and the old ones deleted,
so I needed my S3 bucket to be synchronised on each push:
```yml
  deploy-site:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: jakejarvis/s3-sync-action@master
        with:
          args: --delete
        env:
          AWS_S3_BUCKET: simonresume
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          SOURCE_DIR: resume-site
```

### That's it!
