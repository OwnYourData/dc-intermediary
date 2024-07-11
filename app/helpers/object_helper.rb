module ObjectHelper
    include CollectionHelper
    include StorageHelper

    def create_object(data, org_id, user_id)
        meta = {
            "type": "object",
            "organization-id": org_id,
            "delete": false
        }
        if !data["meta"].nil?
            meta = meta.merge(data["meta"])
            data = data.except("meta")
        end

        dri = Oydid.hash(Oydid.canonical({"data": data, "meta": meta}))
        col_id = data["collection-id"] rescue ""
        if col_id.to_s == ""
            col_id = meta["collection-id"] rescue ""
            if col_id.to_s == ""
            	return [{"error": "missing 'collection-id'"}, 400]
            else
                meta["collection-id"] = col_id.to_s
                data = data.except("collection-id")
            end
        else
            meta["collection-id"] = col_id.to_s
            data = data.except("collection-id")
        end

        col = getCollection(col_id)
        if col.nil?
        	return [{"error": "invalid 'collection-id'"}, 400]
        end
        col_meta = col[:meta]
        if col_meta["type"] != "collection"
            return [{"error": "invalid 'collection-id'"}, 400]
        end
        if col_meta["organization-id"].to_s != org_id.to_s
            return [{"error": "Not authorized"}, 401]
        end

        store = getStorage_by_dri(dri)
        if store.nil?
            store = newStorage(col_id, data, meta, dri, "object_" + col_id.to_s)
        end
        if store[:id].nil?
            return [{"error": store[:error].to_s}, 500]
        else
            createEvent(col_id, CE_CREATE_OBJECT, "create object", {object_id: store[:id], data: data, meta: meta}, user_id)
            return [{"object-id": store[:id], "collection-id": col_id}, 200]
        end
 
    end

    def write_object(id, payload, org_id, user_id)
        payload_dri = Oydid.hash(Oydid.canonical(payload.to_json))
        store = getStorage_by_id(id)
        if store.nil?
        	return [{"error": "not found"}, 404]
        end

        # validate
        data = store[:data].transform_keys(&:to_s) rescue store[:data]
        meta = store[:meta].transform_keys(&:to_s)
        if meta["type"] != "object"
            return [{"error": "not found"}, 404]
        end
        if meta["delete"].to_s.downcase == "true"
            return [{"error": "not found"}, 404]
        end
        if meta["organization-id"].to_s != org_id.to_s
            return [{"error": "Not authorized"}, 401]
        end
        col_id = meta["collection-id"]

        # store payload
        pl_meta = {
            "type": "payload",
            "collection-id": col_id,
            "organization-id": org_id
        }
        if data["payload"].to_s == ""
            pl = newStorage(col_id, payload, pl_meta, payload_dri, nil)
        else
            pl = getStorage_by_dri(payload_dri)
            if pl.nil?
                pl = newStorage(col_id, payload, pl_meta, payload_dri, nil)
            else
                pl = updateStorage(col_id, pl[:id], payload, pl_meta, payload_dri, nil)
            end
        end
        if pl[:id].nil?
            if pl[:error].to_s == ""
            	return [{"error": "cannot save payload"}, 500]
            else
                return [{"error": pl[:error]}, 500]
            end
        else
            data["payload"] = payload_dri
            dri = Oydid.hash(Oydid.canonical({"data": data, "meta": meta}))
            update_store = updateStorage(col_id, store[:id], data, meta, dri, "object_" + col_id.to_s)
            if update_store[:id].nil?
                if update_store[:error].to_s == ""
                	return [{"error": "cannot save update to payload"}, 500]
                else
                	return [{"error": update_store[:error]}, 500]
                end
            else
                createEvent(col_id, CE_WRITE_PAYLOAD, "write payload", {object_id: store[:id], payload_dri: payload_dri, payload: payload}, user_id)
                return [{"object-id": store[:id], "collection-id": col_id}, 200]
            end
        end
    end

end
