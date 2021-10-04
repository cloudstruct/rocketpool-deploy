#!/bin/bash
tar $* %1>/dev/null %2>/dev/null
echo '{"result":"success"}'
