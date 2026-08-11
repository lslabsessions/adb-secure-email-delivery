-- Run as ADMIN or another account allowed to manage network ACLs
-- Replace APP_USER with the schema that will send the e-mails.

SET SERVEROUTPUT ON

DEFINE TARGET_SCHEMA = APP_USER

DECLARE
    l_schema_name VARCHAR2(128) := UPPER('&TARGET_SCHEMA');

    BEGIN
        DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
				host       => 'smtp.email.eu-frankfurt-1.oci.oraclecloud.com',
				lower_port => 587,
				upper_port => 587,
				ace        => xs$ace_type(
				privilege_list => xs$name_list('SMTP'),
                principal_name => l_schema_name,
                principal_type => XS_ACL.PTYPE_DB
            )
        );
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -24243 THEN
                DBMS_OUTPUT.PUT_LINE('SMTP ACE already exists for ' || l_schema_name);
            ELSE
                RAISE;
            END IF;
    END;
/