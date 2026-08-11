DECLARE
    l_connection UTL_SMTP.CONNECTION;

    c_smtp_host CONSTANT VARCHAR2(100) :=
        'smtp.email.eu-frankfurt-1.oci.oraclecloud.com';

    c_sender CONSTANT VARCHAR2(100) :=
        'adb@mail.lslabsessions.com';

    c_recipient CONSTANT VARCHAR2(100) :=
        'info@lslabsessions.com';

    l_message_id VARCHAR2(200);
    l_date       VARCHAR2(100);

BEGIN
     -- RFC-style Date header
    l_date :=
        TO_CHAR(
            SYSTIMESTAMP,
            'Dy, DD Mon YYYY HH24:MI:SS TZH:TZM',
            'NLS_DATE_LANGUAGE=American'
        );

    /*
     * Generate a unique Message-ID for this message.
     */
    l_message_id :=
        '<' ||
        RAWTOHEX(SYS_GUID()) ||
        '@mail.lslabsessions.com>';

    /*
     * Open SMTP connection.
     */
    l_connection :=
        UTL_SMTP.OPEN_CONNECTION(
            host => c_smtp_host,
            port => 587
        );

    /*
     * Advertise SMTP client capabilities.
     */
    UTL_SMTP.EHLO(
        l_connection,
        'mail.lslabsessions.com'
    );

    /*
     * Upgrade connection to TLS.
     */
    UTL_SMTP.STARTTLS(l_connection);

    /*
     * EHLO must be issued again after STARTTLS because
     * the available SMTP capabilities may change.
     */
    UTL_SMTP.EHLO(
        l_connection,
        'mail.lslabsessions.com'
    );

    /*
     * Authenticate using the database credential object.
     * No SMTP password appears in the source code.
     */
    UTL_SMTP.SET_CREDENTIAL(
        c          => l_connection,
        credential => 'LSLABS_EMAIL_CRED',
        schemes    => 'PLAIN'
    );

    /*
     * SMTP envelope.
     */
    UTL_SMTP.MAIL(
        l_connection,
        c_sender
    );

    UTL_SMTP.RCPT(
        l_connection,
        c_recipient
    );

    /*
     * Message headers and body.
     */
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
        'To: ' || c_recipient ||
        UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'Subject: LS Labs - UTL_SMTP.SET_CREDENTIAL RFC test' ||
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
        'Content-Transfer-Encoding: 8bit' ||
        UTL_TCP.CRLF ||
        UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'Hello from Oracle Autonomous Database.' ||
        UTL_TCP.CRLF ||
        UTL_TCP.CRLF ||
        'This email was sent using UTL_SMTP.SET_CREDENTIAL.' ||
        UTL_TCP.CRLF ||
        'SMTP credentials are stored securely in a database credential object.'
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