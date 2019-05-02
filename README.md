# MQonAWS2Slack
Send notifications from IBM MQ on AWS to Slack

Running IBM MQ in the mazon cloud? Yes, that's pretty popular these days. So is Slack. Why not combine the two? If your AWS instances allow connections direct to Slack this isn't too hard. But in most cases the instances are firewalled off and protected by security groups which we can't punch holes in without violating corporate security policies.  What we can do though is pass the notices to Amazon Simple Notification Service (SNS), then use a Lambda function to process them and convert to the Slack webhook format.  Since Lambda is serverless we don't face the same restrictions on outbound connections that we do from the EC2 instance.

There are already several projects that send notifications from EC2 instances to Slack but this one does not rely on Cloudwatch and it provides a server-side tool to hide most of the complexity of the AWS CLI API for publishing to SNS. Instead of formatting a giant JSON string, the caller just needs to specify Slack message elements as individual command-line options. The server-side script and the Lambda function are closely integrated and support the full range of Slack message attachment features including emoji, color, free-form text, multi-line messages, and key/value pairs.

As of this initial release this project contains only the code and this README. The to-do list includes documentation of how to set up the varios AWS services and security groups, as well as scripts for event messages and triggering.
