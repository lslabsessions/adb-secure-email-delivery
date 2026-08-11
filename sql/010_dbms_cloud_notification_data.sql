BEGIN
    DBMS_CLOUD_NOTIFICATION.SEND_DATA(
        provider        => 'email',
        credential_name => 'LSLABS_EMAIL_CRED',

        query => q'[
            SELECT LEVEL AS row_id,
                   'LS Labs row ' || LEVEL AS description
              FROM dual
            CONNECT BY LEVEL <= 5
        ]',

        params => JSON_OBJECT(
            'recipient' VALUE 'info@lslabsessions.com',
            'subject'   VALUE 'LS Labs - Query results from ADB',
            'message'   VALUE 'Attached are query results generated directly by Autonomous Database.',
            'type'      VALUE 'CSV',
            'title'     VALUE 'lslabs_query_results',
            'smtp_host' VALUE 'smtp.email.eu-frankfurt-1.oci.oraclecloud.com',
            'sender'    VALUE 'reports@mail.lslabsessions.com'
        )
    );
END;
/