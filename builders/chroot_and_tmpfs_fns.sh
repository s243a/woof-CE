INTERACT_DEV=1 #s243a: TODO add directive to set and unset this variable
INTERACT_CONSOLE=0 #s243a: TODO add directive to set and unset this variable
DEV_BACKUP_PATH=/dev2
DEV_BACKUP_STATUS='none'
SYS_BACKUP_PATH=/sys2
SYS_BACKUP_STATUS='none'
PROC_BACKUP_PATH=/proc2
PROC_BACKUP_STATUS='none'
backup_DEV(){ 
  if [ "$DEV_BACKUP_STATUS" = 'none' ] && [ -d "$CHROOT_DIR/dev" ]; then
    mv $CHROOT_DIR/dev $CHROOT_DIR$DEV_BACKUP_PATH
    DEV_BACKUP_STATUS='moved'
  fi
}
backup_SYS(){ 
  if [ "$SYS_BACKUP_STATUS" = 'none' ] && [ -d "$CHROOT_DIR/sys" ]; then
    mv $CHROOT_DIR/sys $CHROOT_DIR$SYS_BACKUP_PATH
    SYS_BACKUP_STATUS='moved'
  fi
}
backup_PROC(){ 
  if [ "$PROC_BACKUP_STATUS" = 'none' ] && [ -d "$CHROOT_DIR/proc" ]; then
    mv $CHROOT_DIR/proc $CHROOT_DIR$PROC_BACKUP_PATH
    PROC_BACKUP_STATUS='moved'
  fi
}
restore_DEV(){ 
  if [ "$DEV_BACKUP_STATUS" = 'moved' ]; then
    unbind_DEV #Directory might be bound to the host system
    if [ -z "$(ls -A $CHROOT_DIR/dev )" ]; then #https://superuser.com/a/352290
      rmdir $CHROOT_DIR/dev
      mv $CHROOT_DIR$DEV_BACKUP_PATH $CHROOT_DIR/dev 
      DEV_BACKUP_STATUS='none'
    fi #s243a: TODO maybe add exit status to indicate sucess or failure    
  fi
}
restore_SYS(){ 
  if [ "$SYS_BACKUP_STATUS" = 'moved' ]; then
    unbind_SYS #Directory might be bound to the host system
    if [ -z "$(ls -A $CHROOT_DIR/sys )" ]; then #https://superuser.com/a/352290    
      rmdir $CHROOT_DIR/sys       
      mv $CHROOT_DIR$SYS_BACKUP_PATH $CHROOT_DIR/sys
      SYS_BACKUP_STATUS='none'
    fi
  fi
}
restore_PROC(){ 
  if [ "$PROC_BACKUP_STATUS" = 'moved' ]; then
    unbind_PROC #Directory might be bound to the host system
    if [ -z "$(ls -A $CHROOT_DIR/proc )" ]; then #https://superuser.com/a/352290  
      rmdir $CHROOT_DIR/proc     
      mv $CHROOT_DIR$PROC_BACKUP_PATH $CHROOT_DIR/proc
      PROC_BACKUP_STATUS='none'
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
  if [ "$(mount | grep "$CHROOT_DIR/proc")" = "" ]; then   
    if [ "$PROC_BACKUP_STAUS" = 'moved' ]; then
      rm -rf $CHROOT_DIR$PROC_BACKUP_PATH
    else
      rm -rf $CHROOT_DIR/proc
    fi
    PROC_BACKUP_STAUS='deleted' 
 fi
}
bind_PROC(){
  if [ "$(mount | grep "$CHROOT_DIR/proc")" = "" ]; then
    backup_PROC
    mkdir -p "$CHROOT_DIR/proc"
    if [ -z "$(ls -A $CHROOT_DIR/proc )" ]; then #https://superuser.com/a/352290 
      mount -o rbind /proc $CHROOT_DIR/proc
    fi
  fi
}
bind_SYS(){
  if [ "$(mount | grep "$CHROOT_DIR/sys")" = "" ]; then
    backup_SYS
    mkdir -p "$CHROOT_DIR/sys"    
    if [ -z "$(ls -A $CHROOT_DIR/sys )" ]; then #https://superuser.com/a/352290 
      mount -o rbind /proc $CHROOT_DIR/sys
    fi
  fi
}
bind_DEV(){
  if [ "$(mount | grep "$CHROOT_DIR/dev")" = "" ]; then
    backup_DEV
    mkdir -p "$CHROOT_DIR/dev"  
    if [ -z "$(ls -A $CHROOT_DIR/dev )" ]; then #https://superuser.com/a/352290    
      mount -o rbind /dev $CHROOT_DIR/dev
    fi
  fi
}
bind_ALL(){
  bind_PROC; bind_SYS; [ $INTERACT_DEV -eq 1 ] && bind_DEV
}
unbind_PROC(){
  if [ "$(mount | grep "$CHROOT_DIR/proc")" != "" ]; then
    umount -R -f $CHROOT_DIR/proc
  fi
}
unbind_SYS(){
  if [ "$(mount | grep "$CHROOT_DIR/sys")" != "" ]; then
    umount -R -f $CHROOT_DIR/sys
  fi
}
unbind_DEV(){
  if [ "$(mount | grep "$CHROOT_DIR/dev")" != "" ]; then
    umount -R -f $CHROOT_DIR/dev
  fi
}
unbind_ALL(){
  unbind_PROC; unbind_SYS; unbind_DEV
}
unbind_ALL_lazy(){
  unbind_PROC_lazy; unbind_SYS_lazy; unbind_DEV_lazy
}
unbind_PROC_lazy(){
  if [ "$(mount | grep "$CHROOT_DIR/proc")" != "" ]; then
    umount -R -l $CHROOT_DIR/proc
  fi
}
unbind_SYS_lazy(){
  if [ "$(mount | grep "$CHROOT_DIR/sys")" != "" ]; then
    umount -R -l $CHROOT_DIR/sys
  fi
}
unbind_DEV_lazy(){
  if [ "$(mount | grep "$CHROOT_DIR/dev")" != "" ]; then
    umount -R -l $CHROOT_DIR/dev
  fi
}

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
#TRAP_ON=0 #s243a: TODO consider adding a trap stack
#s243a: TODO add code to remove the trap once we unbind stuff
#if [ $TRAP_ON -eq 0 ]; then #s243a: todo, add a better test here
#  echo "Traps turned off for testing"
#  #trap unmount_vfs EXIT
#  #trap unmount_vfs SIGKILL
#  #trap unmount_vfs SIGTERM
#fi 

