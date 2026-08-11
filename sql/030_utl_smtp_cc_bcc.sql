DECLARE
    l_connection UTL_SMTP.CONNECTION;

    c_smtp_host CONSTANT VARCHAR2(100) :=
        'smtp.email.eu-frankfurt-1.oci.oraclecloud.com';

    c_sender CONSTANT VARCHAR2(100) :=
        'adb@mail.lslabsessions.com';

    c_to  CONSTANT VARCHAR2(100) :=
        'info@lslabsessions.com';

    c_cc  CONSTANT VARCHAR2(100) :=
        '<CC_RECIPIENT>';

    c_bcc CONSTANT VARCHAR2(100) :=
        '<BCC_RECIPIENT>';

    l_date       VARCHAR2(100);
    l_message_id VARCHAR2(200);

BEGIN

	-- RFC-style Date header in UTC
    l_date :=
        TO_CHAR(
            SYS_EXTRACT_UTC(SYSTIMESTAMP),
            'Dy, DD Mon YYYY HH24:MI:SS',
            'NLS_DATE_LANGUAGE=American'
        ) || ' +0000';

    -- Unique message identifier.
    l_message_id :=
        '<' ||
        LOWER(RAWTOHEX(SYS_GUID())) ||
        '@mail.lslabsessions.com>';

    /*
     * Connect to OCI Email Delivery.
     */
    l_connection :=
        UTL_SMTP.OPEN_CONNECTION(
            host => c_smtp_host,
            port => 587
        );

    UTL_SMTP.EHLO(
        l_connection,
        'mail.lslabsessions.com'
    );

    UTL_SMTP.STARTTLS(l_connection);

    UTL_SMTP.EHLO(
        l_connection,
        'mail.lslabsessions.com'
    );

    -- Authenticate using the stored database credential.
    UTL_SMTP.SET_CREDENTIAL(
        c          => l_connection,
        credential => 'LSLABS_EMAIL_CRED',
        schemes    => 'PLAIN'
    );


    -- Every actual recipient requires an RCPT command, including BCC recipients.
    UTL_SMTP.MAIL(
        l_connection,
        c_sender
    );

    UTL_SMTP.RCPT(
        l_connection,
        c_to
    );

    UTL_SMTP.RCPT(
        l_connection,
        c_cc
    );

    UTL_SMTP.RCPT(
        l_connection,
        c_bcc
    );

    -- Message headers.
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
        'To: ' || c_to || UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'Cc: ' || c_cc || UTL_TCP.CRLF
    );

    /*
     Deliberately NO Bcc header.
     The BCC recipient receives the message through SMTP RCPT,
     but the address is not exposed in the message headers.
     */

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'Subject: LS Labs - UTL_SMTP CC and BCC test' ||
        UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'MIME-Version: 1.0' ||
        UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'Content-Type: text/plain; charset=UTF-8' ||
        UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'Content-Transfer-Encoding: 7bit' ||
        UTL_TCP.CRLF ||
        UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'This message demonstrates To, CC and BCC with UTL_SMTP.' ||
        UTL_TCP.CRLF ||
        'The BCC recipient is part of the SMTP envelope but is not exposed in the message headers.'
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