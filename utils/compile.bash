nim c -d:danger src/cw_client &&
mv src/cw_client . &&
nim c -d:danger src/cw_server &&
mv src/cw_server . &&
nim c -d:danger src/cw_webui &&
mv src/cw_webui .
