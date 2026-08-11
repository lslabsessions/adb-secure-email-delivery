-- Replace <SMTP_USERNAME> and <SMTP_PASSWORD> locally in UTL_SMTP.AUTH

DECLARE
    l_connection UTL_SMTP.CONNECTION;

    c_smtp_host CONSTANT VARCHAR2(100) :=
        'smtp.email.eu-frankfurt-1.oci.oraclecloud.com';

    c_sender CONSTANT VARCHAR2(100) :=
        'adb@mail.lslabsessions.com';

    c_recipient CONSTANT VARCHAR2(100) :=
        'info@lslabsessions.com';

    l_date       VARCHAR2(100);
    l_message_id VARCHAR2(200);

BEGIN
     -- RFC-style Date header in UTC.
    l_date :=
        TO_CHAR(
            SYS_EXTRACT_UTC(SYSTIMESTAMP),
            'Dy, DD Mon YYYY HH24:MI:SS',
            'NLS_DATE_LANGUAGE=American'
        ) || ' +0000';

    -- Generate a unique Message-ID.
    l_message_id :=
        '<' || LOWER(RAWTOHEX(SYS_GUID())) ||
        '@mail.lslabsessions.com>';


    -- Connect to OCI Email Delivery.
    l_connection :=
        UTL_SMTP.OPEN_CONNECTION(
            host => c_smtp_host,
            port => 587
        );


    UTL_SMTP.EHLO(
        l_connection,
        'mail.lslabsessions.com'
    );


    -- Upgrade the connection to TLS
    UTL_SMTP.STARTTLS(l_connection);


    UTL_SMTP.EHLO(
        l_connection,
        'mail.lslabsessions.com'
    );

	--  Authenticate using explicit SMTP credentials (Never commit real SMTP credentials to source control)

    UTL_SMTP.AUTH(
        c        => l_connection,
        username => '<SMTP_USERNAME>',
        password => '<SMTP_PASSWORD>',
        schemes  => 'PLAIN'
    );


    -- SMTP envelope.
    UTL_SMTP.MAIL(
        l_connection,
        c_sender
    );

    UTL_SMTP.RCPT(
        l_connection,
        c_recipient
    );


    -- RFC-style message headers and body.
    UTL_SMTP.OPEN_DATA(l_connection);

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'Date: ' || l_date || UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'Message-ID: ' || l_message_id || UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'From: LS Labs ADB <' || c_sender || '>' ||
        UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'To: ' || c_recipient || UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'Subject: LS Labs - UTL_SMTP.AUTH test' ||
        UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'MIME-Version: 1.0' || UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'Content-Type: text/plain; charset=UTF-8' ||
        UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'Content-Transfer-Encoding: 7bit' ||
        UTL_TCP.CRLF || UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'Hello from Oracle Autonomous Database.' ||
        UTL_TCP.CRLF || UTL_TCP.CRLF ||
        'This message was authenticated using UTL_SMTP.AUTH.' ||
        UTL_TCP.CRLF ||
        'The SMTP username and password were supplied directly to the AUTH call.'
    );

    UTL_SMTP.CLOSE_DATA(l_connection);
    UTL_SMTP.QUIT(l_connection);

EXCEPTION
    WHEN OTHERS THEN
        BEGIN
            UTL_SMTP.QUIT(l_connection);
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;

        RAISE;
END;
/