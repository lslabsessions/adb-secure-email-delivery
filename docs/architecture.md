# Architecture

This document explains the different layers involved in the email lab and why each one exists.

The main point is that sending an email is not a single authentication step. Database network access, SMTP authentication, OCI authorization, sender authorization, message construction, and public-domain authentication are separate concerns.

## Outbound flow

The outbound path used by the lab is:

```text
Oracle Autonomous Database
        │
        │ SMTP port 587
        │ STARTTLS
        │ SMTP authentication
        ▼
OCI Email Delivery
        │
        │ DKIM-signed outbound message
        ▼
Recipient mail infrastructure
        │
        ├── SPF validation
        ├── DKIM validation
        ├── DMARC evaluation
        └── spam / reputation filtering
        │
        ▼
Recipient mailbox
```

The database does not connect directly to Gmail or Outlook. It submits the message to OCI Email Delivery, which acts as the outbound delivery service.

## Domain design

The project uses:

```text
lslabsessions.com
```

as the root domain and:

```text
mail.lslabsessions.com
```

as the dedicated outbound sending subdomain.

This separation is useful because the root domain is also used for inbound forwarding.

```text
Inbound path

info@lslabsessions.com
        ↓
Namecheap forwarding
        ↓
Receiving mailbox
```

The inbound forwarding path is independent from the outbound OCI Email Delivery path.

## OCI layer

The OCI side contains several different resources:

```text
Email Domain
    → establishes mail.lslabsessions.com as a sending domain

DKIM
    → allows OCI Email Delivery to sign messages for the domain

Approved Sender
    → authorizes the sending identity/domain in Email Delivery

IAM service user
    → identity used to own the SMTP credentials

IAM group + policy
    → grants the required Email Delivery permission

SMTP credentials
    → username/password pair used by the SMTP client
```

These resources are related, but they are not interchangeable.

An IAM policy does not replace an Approved Sender. An Approved Sender does not replace SMTP authentication. SMTP authentication does not replace SPF, DKIM, or DMARC.

## Autonomous Database layer

The database side contains two separate controls.

### Network ACE

The network Access Control Entry authorizes the schema to connect to:

```text
smtp.email.eu-frankfurt-1.oci.oraclecloud.com
```

on:

```text
TCP 587
```

with the SMTP privilege.

This answers:

> Is this database schema allowed to open an SMTP connection to this host and port?

It does not authenticate the schema to OCI Email Delivery.

### Database credential object

The credential object created with `DBMS_CLOUD.CREATE_CREDENTIAL` stores the SMTP username/password pair for later use.

The application can refer to:

```text
LSLABS_EMAIL_CRED
```

instead of receiving the SMTP password directly in the sending PL/SQL call.

## Two PL/SQL paths

The repository compares two ways of submitting email.

### Higher-level path

```text
PL/SQL
  ↓
DBMS_CLOUD_NOTIFICATION
  ↓
OCI Email Delivery
```

For email, `DBMS_CLOUD_NOTIFICATION` accepts parameters such as:

```text
credential_name
smtp_host
sender
recipient
to_cc
to_bcc
subject
```

The package hides the SMTP conversation and most message-construction details.

### Lower-level path

```text
PL/SQL
  ↓
UTL_SMTP
  ↓
SMTP commands
  ↓
OCI Email Delivery
```

The application explicitly performs operations such as:

```text
OPEN_CONNECTION
EHLO
STARTTLS
EHLO
AUTH or SET_CREDENTIAL
MAIL
RCPT
OPEN_DATA
WRITE_DATA / WRITE_RAW_DATA
CLOSE_DATA
QUIT
```

This path requires more code but provides direct control over the message.

## SMTP envelope versus message

One of the most important distinctions in the lab is the difference between the SMTP envelope and the message itself.

The SMTP envelope contains delivery instructions:

```text
MAIL FROM
RCPT TO
```

The RFC 5322 message contains visible headers:

```text
Date:
Message-ID:
From:
To:
Cc:
Subject:
```

A BCC recipient still receives an SMTP `RCPT` command, but the BCC address does not need to appear in the visible message headers.

That is why `UTL_SMTP` can send a message to a BCC recipient while omitting the `Bcc:` header from the message presented to other recipients.

## MIME layer

MIME extends the message body so that it can contain different media types and attachments.

The attachment example uses:

```text
multipart/mixed
│
├── text/plain
│
└── text/csv
    Content-Disposition: attachment
    Content-Transfer-Encoding: base64
```

A MIME boundary separates each part.

If the same body is available as both plain text and HTML, a nested structure can be used:

```text
multipart/mixed
│
├── multipart/alternative
│   ├── text/plain
│   └── text/html
│
└── attachment.csv
```

Each nested multipart uses a different boundary.

## Receiving side

After OCI Email Delivery submits the message to the recipient infrastructure, several checks can happen independently:

```text
SPF
DKIM
DMARC
spam filtering
sender/domain reputation
provider-specific rules
```

This explains why an email can pass SPF, DKIM, and DMARC and still be placed in Junk.

Authentication and deliverability are related, but they are not the same thing.

## Screenshot evidence

A few representative screenshots connect the conceptual architecture to the real lab.

![OCI Email Domain authentication active](screenshots/016-email-domain-authentication-active.jpg)

![DBMS_CLOUD_NOTIFICATION delivered message](screenshots/030-dbms-cloud-notification-message.jpg)

![Receiving-side authentication result](screenshots/080-dmarc-pass.jpg)

## References

- [Send Email on Autonomous AI Database](https://docs.oracle.com/en-us/iaas/autonomous-database-serverless/doc/smtp-send-mail.html)
- [DBMS_CLOUD_NOTIFICATION Package](https://docs.oracle.com/en/cloud/paas/autonomous-database/serverless/adbsb/autonomous-dbms-cloud-notification.html)
- [OCI Email Delivery Overview](https://docs.oracle.com/en-us/iaas/Content/Email/Concepts/overview.htm)
- [RFC 5321](https://www.rfc-editor.org/info/rfc5321/)
- [RFC 5322](https://www.rfc-editor.org/info/rfc5322/)
- [RFC 2045](https://www.rfc-editor.org/info/rfc2045/)
- [RFC 2046](https://www.rfc-editor.org/info/rfc2046/)
