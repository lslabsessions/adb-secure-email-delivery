-- Replace placeholders locally. Never commit real SMTP credentials.

BEGIN
  DBMS_CLOUD.CREATE_CREDENTIAL(
    credential_name => 'LSLABS_EMAIL_CRED',
    username        => '<SMTP_USERNAME>',
    password        => '<SMTP_PASSWORD>'
  );
END;
/