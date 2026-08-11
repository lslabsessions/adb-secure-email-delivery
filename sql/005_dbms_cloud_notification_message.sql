BEGIN
    DBMS_CLOUD_NOTIFICATION.SEND_MESSAGE(
        provider        => 'email',
        credential_name => 'LSLABS_EMAIL_CRED', 
        message         => 'Hello from Oracle Autonomous Database. ' ||
                           'This message was sent using DBMS_CLOUD_NOTIFICATION.',
        params          => JSON_OBJECT(
            'recipient' VALUE 'info@lslabsessions.com',
            'subject'   VALUE 'LS Labs - DBMS_CLOUD_NOTIFICATION test',
            'smtp_host' VALUE 'smtp.email.eu-frankfurt-1.oci.oraclecloud.com',
            'sender'    VALUE 'adb@mail.lslabsessions.com'
        )
    );
END;
/