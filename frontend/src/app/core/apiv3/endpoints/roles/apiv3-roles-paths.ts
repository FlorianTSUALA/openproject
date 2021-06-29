//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See docs/COPYRIGHT.rdoc for more details.
//++

import { APIv3ResourceCollection, APIv3ResourcePath } from "core-app/core/apiv3/paths/apiv3-resource";
import { Injector } from "@angular/core";
import { RoleResource } from "core-app/features/hal/resources/role-resource";
import { APIv3RolePaths } from "core-app/core/apiv3/endpoints/roles/apiv3-role-paths";
import { Observable } from "rxjs";
import { CollectionResource } from "core-app/features/hal/resources/collection-resource";
import { tap } from "rxjs/operators";
import { APIV3Service } from "core-app/core/apiv3/api-v3.service";

export class APIv3RolesPaths extends APIv3ResourceCollection<RoleResource, APIv3RolePaths> {
  constructor(protected apiRoot:APIV3Service,
    protected basePath:string) {
    super(apiRoot, basePath, 'roles', APIv3RolePaths);
  }

  /**
   * Perform a request to the HalResourceService with the current path
   */
  public get():Observable<CollectionResource<RoleResource>> {
    return this
      .halResourceService
      .get<CollectionResource<RoleResource>>(this.path)
      .pipe(
        tap(collection => {
          collection.elements.forEach((resource, id) => {
            this.id(resource.id!).cache.updateValue(resource.id!, resource);
          });
        }),
      );
  }
}
