import DS from 'ember-data';

export default DS.RESTSerializer.extend({
    isNewSerializerAPI: true,
    modelNameFromPayloadKey: function(name) {
        return name;
    }
});
