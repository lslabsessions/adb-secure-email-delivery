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
    l_html       VARCHAR2(32767);

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
        '<' || LOWER(RAWTOHEX(SYS_GUID())) ||
        '@mail.lslabsessions.com>';

    
    -- HTML body containing UTF-8 characters
    l_html :=
        '<!DOCTYPE html>' ||
        '<html>' ||
        '<body>' ||
        '<h2>LS Labs - Oracle Autonomous Database</h2>' ||
        '<p>Olá!</p>' ||
        '<p>This email contains HTML and UTF-8 text.</p>' ||
        '<p>UTF-8 test: acentuação, coração, café, €.</p>' ||
        '<p><strong>Authentication:</strong> ' ||
        'UTL_SMTP.SET_CREDENTIAL</p>' ||
        '</body>' ||
        '</html>';

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

    UTL_SMTP.MAIL(
        l_connection,
        c_sender
    );

    UTL_SMTP.RCPT(
        l_connection,
        c_recipient
    );


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
        'Subject: LS Labs - HTML and UTF-8 test' ||
        UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'MIME-Version: 1.0' ||
        UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'Content-Type: text/html; charset=UTF-8' ||
        UTL_TCP.CRLF
    );

    UTL_SMTP.WRITE_DATA(
        l_connection,
        'Content-Transfer-Encoding: 8bit' ||
        UTL_TCP.CRLF ||
        UTL_TCP.CRLF
    );

    -- Convert the VARCHAR2 explicitly to UTF-8 RAW bytes (WRITE_DATA would convert VARCHAR2 to US7ASCII)
    UTL_SMTP.WRITE_RAW_DATA(
        l_connection,
        UTL_I18N.STRING_TO_RAW(
            l_html,
            'AL32UTF8'
        )
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