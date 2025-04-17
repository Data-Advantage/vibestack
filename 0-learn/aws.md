# Amazon Web Services (AWS)

AWS is a comprehensive cloud platform offering over 200 services from data centers globally. In VibeStack, AWS provides infrastructure for hosting, storage, and various application services.

## Core AWS Services for VibeStack

### EC2 (Elastic Compute Cloud)

Virtual servers in the cloud that provide resizable compute capacity:

```bash
# Connecting to an EC2 instance
ssh -i "your-key.pem" ec2-user@your-instance-public-dns.amazonaws.com
```

Key configuration aspects:
- **AMI Selection**: Choose Amazon Linux 2023, Ubuntu, or other distributions based on your needs
- **Instance Types**: Select based on compute/memory requirements (t2.micro for testing, t3.medium for production)
- **Security Groups**: Configure as a virtual firewall to control traffic

### S3 (Simple Storage Service)

Object storage service offering scalability, data availability, and security:

```javascript
// Uploading a file to S3 using AWS SDK
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";

const s3Client = new S3Client({ region: "us-east-1" });

export async function uploadFile(fileBuffer, fileName, contentType) {
  const params = {
    Bucket: "your-vibestack-bucket",
    Key: fileName,
    Body: fileBuffer,
    ContentType: contentType,
    ACL: "private", // or "public-read" if content should be publicly accessible
  };

  try {
    const command = new PutObjectCommand(params);
    await s3Client.send(command);
    return `https://your-vibestack-bucket.s3.amazonaws.com/${fileName}`;
  } catch (error) {
    console.error("Error uploading file:", error);
    throw error;
  }
}
```

Best practices:
- Enable versioning for critical buckets
- Set up lifecycle policies for cost management
- Use appropriate bucket policies and IAM roles

### RDS (Relational Database Service)

Managed relational database service supporting PostgreSQL, MySQL, and other database engines:

```typescript
// Database connection configuration for PostgreSQL on RDS
import { Pool } from 'pg';

const pool = new Pool({
  host: 'your-db-instance.region.rds.amazonaws.com',
  port: 5432,
  database: 'vibestack',
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  ssl: {
    rejectUnauthorized: false // In production, use proper SSL configuration
  }
});

export default pool;
```

Setup considerations:
- Multi-AZ deployment for high availability
- Configure automated backups
- Choose appropriate instance class based on workload

### Lambda

Serverless compute service that runs code in response to events:

```typescript
// Example AWS Lambda function for image processing
import { S3Event } from 'aws-lambda';
import { S3Client, GetObjectCommand, PutObjectCommand } from '@aws-sdk/client-s3';
import sharp from 'sharp';

const s3 = new S3Client({ region: 'us-east-1' });

export const handler = async (event: S3Event) => {
  const record = event.Records[0];
  const bucket = record.s3.bucket.name;
  const key = decodeURIComponent(record.s3.object.key.replace(/\+/g, ' '));
  
  try {
    // Get the original image
    const getObjectParams = {
      Bucket: bucket,
      Key: key,
    };
    const { Body } = await s3.send(new GetObjectCommand(getObjectParams));
    const imageBuffer = await streamToBuffer(Body);
    
    // Process the image - resize to thumbnail
    const thumbnail = await sharp(imageBuffer)
      .resize(200, 200, { fit: 'inside' })
      .toBuffer();
    
    // Upload the thumbnail
    const thumbnailKey = `thumbnails/${key.split('/').pop()}`;
    const putObjectParams = {
      Bucket: bucket,
      Key: thumbnailKey,
      Body: thumbnail,
      ContentType: 'image/jpeg',
    };
    
    await s3.send(new PutObjectCommand(putObjectParams));
    
    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Thumbnail created successfully' }),
    };
  } catch (error) {
    console.error('Error processing image:', error);
    throw error;
  }
};

// Helper function to convert stream to buffer
async function streamToBuffer(stream) {
  const chunks = [];
  for await (const chunk of stream) {
    chunks.push(chunk);
  }
  return Buffer.concat(chunks);
}
```

Deployment options:
- Direct upload via AWS Console
- AWS Serverless Application Model (SAM)
- Infrastructure as Code using CloudFormation or CDK

### CloudFront

Content Delivery Network (CDN) service for global content delivery:

```typescript
// Generating signed URLs for private CloudFront content
import { getSignedUrl } from '@aws-sdk/cloudfront-signer';

export function generateSignedUrl(resourceUrl: string) {
  const privateKey = process.env.CLOUDFRONT_PRIVATE_KEY!;
  const keyPairId = process.env.CLOUDFRONT_KEY_PAIR_ID!;
  
  // URL expires in 1 hour
  const expiresAt = new Date(Date.now() + 60 * 60 * 1000);
  
  return getSignedUrl({
    url: `https://your-distribution.cloudfront.net/${resourceUrl}`,
    keyPairId,
    dateLessThan: expiresAt.toISOString(),
    privateKey
  });
}
```

Configuration best practices:
- Use a custom domain with SSL/TLS certificate
- Configure cache behaviors based on content type
- Set appropriate TTLs for different content types

## AWS Infrastructure for VibeStack

### VPC (Virtual Private Cloud)

Create an isolated network environment:

```bash
# Creating a VPC using AWS CLI
aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=VibeStack-VPC}]'
```

Recommended architecture:
- At least two availability zones
- Public and private subnets
- NAT gateway for private subnet internet access
- Network ACLs and security groups for defense in depth

### IAM (Identity and Access Management)

Secure access to AWS services:

```json
// Example IAM policy for S3 access with least privilege
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::your-vibestack-bucket/uploads/${aws:userid}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": "arn:aws:s3:::your-vibestack-bucket",
      "Condition": {
        "StringLike": {
          "s3:prefix": [
            "uploads/${aws:userid}/*"
          ]
        }
      }
    }
  ]
}
```

Security best practices:
- Follow principle of least privilege
- Use IAM roles instead of access keys when possible
- Implement MFA for all IAM users
- Regularly audit IAM policies and permissions

### Route 53

DNS service for domain registration and routing:

```typescript
// Example of programmatically creating a DNS record
import { Route53Client, ChangeResourceRecordSetsCommand } from "@aws-sdk/client-route-53";

const route53 = new Route53Client({ region: "us-east-1" });

export async function createDnsRecord(domainName, subdomain, recordValue, recordType = 'A') {
  const params = {
    HostedZoneId: 'YOUR_HOSTED_ZONE_ID',
    ChangeBatch: {
      Changes: [
        {
          Action: 'UPSERT',
          ResourceRecordSet: {
            Name: subdomain ? `${subdomain}.${domainName}` : domainName,
            Type: recordType,
            TTL: 300,
            ResourceRecords: [
              {
                Value: recordValue
              }
            ]
          }
        }
      ]
    }
  };

  const command = new ChangeResourceRecordSetsCommand(params);
  return route53.send(command);
}
```

Configuration options:
- Public hosted zones for internet-facing DNS
- Private hosted zones for VPC-specific DNS
- Health checks and routing policies (failover, geolocation, latency-based)

## Deployment Options

### Elastic Beanstalk

Simplified deployment service that handles provisioning, load balancing, and scaling:

```yaml
# .elasticbeanstalk/config.yml example
branch-defaults:
  main:
    environment: vibestack-prod
    group_suffix: null
global:
  application_name: vibestack
  branch: null
  default_ec2_keyname: aws-eb
  default_platform: Node.js 16
  default_region: us-east-1
  include_git_submodules: true
  instance_profile: null
  platform_name: null
  platform_version: null
  profile: eb-cli
  repository: null
  sc: git
  workspace_type: Application
```

Deployment considerations:
- Environment configurations (web server vs. worker)
- Environment variables for secrets and configuration
- Deployment policies (all at once, rolling, immutable)

### ECS (Elastic Container Service)

Container orchestration service for Docker containers:

```yaml
# Task definition example
{
  "family": "vibestack-app",
  "executionRoleArn": "arn:aws:iam::123456789012:role/ecsTaskExecutionRole",
  "networkMode": "awsvpc",
  "containerDefinitions": [
    {
      "name": "vibestack-web",
      "image": "123456789012.dkr.ecr.us-east-1.amazonaws.com/vibestack:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "NODE_ENV",
          "value": "production"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/vibestack-app",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ],
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512"
}
```

Deployment strategies:
- Fargate (serverless) vs. EC2 (self-managed)
- Service auto scaling based on CPU or memory utilization
- Task definition versioning for rollback capability

### Amplify

Fully managed CI/CD and hosting service for web applications:

```yaml
# amplify.yml configuration
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - npm ci
    build:
      commands:
        - npm run build
  artifacts:
    baseDirectory: .next
    files:
      - '**/*'
  cache:
    paths:
      - node_modules/**/*
```

Features:
- Automatic deployments from Git
- Preview environments for pull requests
- Branch-based environments
- Authentication and API integration

## Monitoring and Observability

### CloudWatch

Monitoring and observability service with metrics, logs, and alarms:

```typescript
// Setting up a CloudWatch alarm programmatically
import { CloudWatchClient, PutMetricAlarmCommand } from "@aws-sdk/client-cloudwatch";

const cloudwatch = new CloudWatchClient({ region: "us-east-1" });

async function createCpuAlarm(instanceId, threshold = 80) {
  const params = {
    AlarmName: `HighCPU-${instanceId}`,
    ComparisonOperator: "GreaterThanThreshold",
    EvaluationPeriods: 2,
    MetricName: "CPUUtilization",
    Namespace: "AWS/EC2",
    Period: 300,
    Statistic: "Average",
    Threshold: threshold,
    ActionsEnabled: true,
    AlarmDescription: `Alarm when CPU exceeds ${threshold}% for 10 minutes`,
    Dimensions: [
      {
        Name: "InstanceId",
        Value: instanceId
      }
    ],
    AlarmActions: [
      "arn:aws:sns:us-east-1:123456789012:AlertNotifications"
    ]
  };

  const command = new PutMetricAlarmCommand(params);
  return cloudwatch.send(command);
}
```

Monitoring best practices:
- Set up dashboards for key metrics
- Configure alarms for critical thresholds
- Use metric filters for log-based metrics
- Implement structured logging for better search capabilities

### X-Ray

Distributed tracing service for application analysis and debugging:

```typescript
// Instrumenting a Next.js API route with AWS X-Ray
import AWSXRay from 'aws-xray-sdk';
import { NextApiRequest, NextApiResponse } from 'next';

// Configure X-Ray
AWSXRay.setDaemonAddress('xray-daemon.default:2000');
AWSXRay.middleware.setSamplingRules({
  version: 2,
  rules: [
    {
      description: "Default",
      host: "*",
      http_method: "*",
      url_path: "*",
      fixed_target: 1,
      rate: 0.1
    }
  ],
  default: { fixed_target: 0, rate: 0 }
});

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  const segment = new AWSXRay.Segment('api-handler');
  
  const subSegment = segment.addNewSubsegment('business-logic');
  try {
    // Your API logic here
    
    subSegment.close();
    res.status(200).json({ success: true });
  } catch (error) {
    subSegment.addError(error);
    subSegment.close();
    res.status(500).json({ error: 'Internal Server Error' });
  } finally {
    segment.close();
  }
}
```

Integration options:
- Automatic instrumentation for supported frameworks
- Manual instrumentation for custom code
- AWS SDK clients auto-instrumentation
- Viewing service maps and trace details

## Cost Management

### AWS Budget

Set up budgets and alerts to monitor costs:

```bash
# Creating a budget using AWS CLI
aws budgets create-budget \
  --account-id 123456789012 \
  --budget file://budget.json \
  --notifications-with-subscribers file://notifications.json
```

Cost optimization strategies:
- Right-size resources based on actual usage
- Use reserved instances or savings plans for predictable workloads
- Set up lifecycle policies for S3 objects
- Implement auto-scaling to match demand

### Cost Explorer

Analyze and visualize your AWS costs:

- **Cost and Usage Reports**: Detailed cost breakdowns
- **Resource Optimization**: Recommendations for savings
- **Reservation Analysis**: Evaluate RI/SP coverage and utilization

## Security Best Practices

1. **Enable MFA** for all IAM users
2. **Encrypt data** at rest and in transit
3. **Implement security groups** with least privilege access
4. **Rotate credentials** regularly
5. **Use IAM roles** instead of access keys for services
6. **Enable CloudTrail** for auditing API calls
7. **Configure GuardDuty** for threat detection
8. **Implement Security Hub** for security posture management

## Resources

- [AWS Documentation](https://docs.aws.amazon.com/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS SDK for JavaScript](https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/)
- [AWS CDK Documentation](https://docs.aws.amazon.com/cdk/latest/guide/)
- [AWS CLI Reference](https://awscli.amazonaws.com/v2/documentation/api/latest/index.html)
