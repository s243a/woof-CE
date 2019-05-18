INTERACT_DEV=1 #s243a: TODO add directive to set and unset this variable
INTERACT_CONSOLE=0 #s243a: TODO add directive to set and unset this variable
DEV_BACKUP_PATH=/dev2
DEV_BACKUP_STAUS='none'
SYS_BACKUP_PATH=/sys2
SYS_BACKUP_STAUS='none'
PROC_BACKUP_PATH=/proc2
PROC_BACKUP_STATUS='none'
backup_DEV(){ 
  if [ "$DEV_BACKUP_STAUS" = 'none' ]; then
    mv $CHROOT_DIR/dev $CHROOT_DIR$DEV_BACKUP_PATH
    DEV_BACKUP_STAUS='moved'
  fi
}
backup_SYS(){ 
  if [ "$SYS_BACKUP_STAUS" = 'none' ]; then
    mv $CHROOT_DIR/sys $CHROOT_DIR$SYS_BACKUP_PATH
    SYS_BACKUP_STAUS='moved'
  fi
}
backup_PROC(){ 
  if [ "$PROC_BACKUP_STAUS" = 'none' ]; then
    mv $CHROOT_DIR/sys $CHROOT_DIR$SYS_BACKUP_PATH
    PROC_BACKUP_STAUS='moved'
  fi
}
restore_DEV(){ 
  if [ "$DEV_BACKUP_STAUS" = 'moved' ]; then
    unbind_DEV #Directory might be bound to the host system
    if [ -z "$(ls -A $CHROOT_DIR/dev )" ]; then #https://superuser.com/a/352290
      rmdir $CHROOT_DIR/dev
      mv $CHROOT_DIR$DEV_BACKUP_PATH $CHROOT_DIR/dev 
      DEV_BACKUP_STAUS='none'
    fi #s243a: TODO maybe add exit status to indicate sucess or failure    
  fi
}
restore_SYS(){ 
  if [ "$SYS_BACKUP_STAUS" = 'moved' ]; then
    unbind_SYS #Directory might be bound to the host system
    if [ -z "$(ls -A $CHROOT_DIR/sys )" ]; then #https://superuser.com/a/352290    
      rmdir $CHROOT_DIR/sys       
      mv $CHROOT_DIR$SYS_BACKUP_PATH $CHROOT_DIR/sys
      SYS_BACKUP_STAUS='none'
    fi
  fi
}
restore_PROC(){ 
  if [ "$PROC_BACKUP_STAUS" = 'moved' ]; then
    unbind_PROC #Directory might be bound to the host system
    if [ -z "$(ls -A $CHROOT_DIR/proc )" ]; then #https://superuser.com/a/352290  
      rmdir $CHROOT_DIR/proc     
      mv $CHROOT_DIR$SYS_BACKUP_PATH $CHROOT_DIR/sys
      PROC_BACKUP_STAUS='none'
    fi
  fi
}
del_DEV(){ 
  unbind_DEB
  if [ "$(mount | grep "$CHROOT_DIR/dev")" = "" ]; then
    if [ "$DEV_BACKUP_STAUS" = 'moved' ]; then
      rm -rf $CHROOT_DIR$DEV_BACKUP_PATH
    else #TODO add check to make sure this isn't mounted or busy
      rm -rf $CHROOT_DIR/dev
    fi
    DEV_BACKUP_STAUS='deleted'  
  fi
}
del_SYS(){ 
  unbind_SYS
  if [ "$(mount | grep "$CHROOT_DIR/sys")" = "" ]; then   
    if [ "$SYS_BACKUP_STAUS" = 'moved' ]; then
      rm -rf $CHROOT_DIR$SYS_BACKUP_PATH
    else #TODO add check to make sure this isn't mounted or busy
      rm -rf $CHROOT_DIR/sys
    fi
    SYS_BACKUP_STAUS='deleted'  
  fi
}
del_PROC(){ 
  unbind_PROC
  if [ "$(mount | grep "$CHROOT_DIR/sys")" = "" ]; then   
    if [ "$PROC_BACKUP_STAUS" = 'moved' ]; then
      rm -rf $CHROOT_DIR$SYS_BACKUP_PATH
    else
      rm -rf $CHROOT_DIR/proc
    fi
    PROC_BACKUP_STAUS='deleted' 
 fi
}
bind_PROC(){
  if [ "$(mount | grep "$CHROOT_DIR/proc")" = "" ]; then
    backup_PROC
    mount -o rbind /proc $CHROOT_DIR/proc
  fi
}
bind_SYS(){
  if [ "$(mount | grep "$CHROOT_DIR/proc")" = "" ]; then
    backup_SYS
    mount -o rbind /proc $CHROOT_DIR/sys
  fi
}
bind_DEV(){
  if [ "$(mount | grep "$CHROOT_DIR/dev")" = "" ]; then
    backup_DEV
    mount -o rbind /proc $CHROOT_DIR/dev
  fi
}
bind_ALL(){
  bind_PROC; bind_SYS; [ INTERACT_DEV -eq 1 ] && bind_DEV
}
unbind_PROC(){
  if [ "$(mount | grep "$CHROOT_DIR/proc")" = "" ]; then
    umount -l $CHROOT_DIR/proc
  fi
}
unbind_SYS(){
  if [ "$(mount | grep "$curdir/$rel_rootfs/sys")" != "" ]; then
    umount -l $CHROOT_DIR/sys
  fi
}
unbind_DEV(){
  if [ "$(mount | grep "$curdir/$rel_rootfs/dev")" != "" ]; then
    umount -l $CHROOT_DIR/dev
  fi
}

TRAP_ON=0 #s243a: TODO consider adding a trap stack
unmount_vfs(){
 unbind_proc
 unbind_sys
 unbind_dev
 restore_proc
 restore_sys
 restore_dev
}  
bind_dev(){
  backup_DEV
  mkdir -p $CHROOT_DIR/dev
  mount -o rbind /dev $curdir/$rel_rootfs/dev
}
#s243a: TODO add code to remove the trap once we unbind stuff
if [ TRAP_ON -eq 0 ]; then #s243a: todo, add a better test here
  trap unmount_vfs EXIT
  trap unmount_vfs SIGKILL
  trap unmount_vfs SIGTERM
fi 

