#!/bin/bash

VBoxManage snapshot imagebuilder restorecurrent
VBoxHeadless -s imagebuilder --vrde off &
sleep 10
ssh -p 3022 denis@127.0.0.1
VBoxManage controlvm imagebuilder poweroff
VBoxManage snapshot imagebuilder restorecurrent
