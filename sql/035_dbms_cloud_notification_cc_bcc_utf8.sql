BEGIN
    DBMS_CLOUD_NOTIFICATION.SEND_MESSAGE(
        provider        => 'email',
        credential_name => 'LSLABS_EMAIL_CRED',

        message =>
            'Olá from Oracle Autonomous Database! ' ||
            'UTF-8 test: acentuação, coração, café, €.',

        params => JSON_OBJECT(
            'recipient' VALUE 'info@lslabsessions.com',
            'to_cc'     VALUE '<CC_RECIPIENT>',
            'to_bcc'    VALUE '<BCC_RECIPIENT>',
            'subject'   VALUE 'LS Labs - DBMS_CLOUD_NOTIFICATION UTF-8 + CC/BCC',
            'smtp_host' VALUE 'smtp.email.eu-frankfurt-1.oci.oraclecloud.com',
            'sender'    VALUE 'adb@mail.lslabsessions.com'
        )
    );
END;
/