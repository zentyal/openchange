/*
   OpenChange MAPI PHP bindings

   Copyright (C) 2013 Zentyal S.L.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef MAPI_FOLDER_H
#define MAPI_FOLDER_H

typedef struct mapi_folder_object
{
	zend_object	std;
	TALLOC_CTX	*talloc_ctx;
	zval		*parent_mailbox;
	uint64_t        id;
	mapi_object_t	store;
	char		*folder_type;
} mapi_folder_object_t;

#ifndef __BEGIN_DECLS
#ifdef __cplusplus
#define __BEGIN_DECLS		extern "C" {
#define __END_DECLS		}
#else
#define __BEGIN_DECLS
#define __END_DECLS
#endif
#endif

__BEGIN_DECLS

PHP_METHOD(MAPIFolder, __construct);
PHP_METHOD(MAPIFolder, __destruct);
PHP_METHOD(MAPIFolder, getFolderType);
PHP_METHOD(MAPIFolder, getFolderTable);
PHP_METHOD(MAPIFolder, getMessageTable);
PHP_METHOD(MAPIFolder, openMessage);
PHP_METHOD(MAPIFolder, createMessage);

void MAPIFolderRegisterClass(TSRMLS_D);
zval *create_folder_object(zval *php_mailbox, uint64_t id, char *item_type TSRMLS_DC);

__END_DECLS

#endif
