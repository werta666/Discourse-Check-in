import Controller from "@ember/controller";

export default Controller.extend({
  activeTab: "check-in",
  showSuccessMessage: false,
  successMessage: "",

  actions: {
    switchTab(tabName) {
      this.set('activeTab', tabName);
    },

    hideMessage() {
      this.set('showSuccessMessage', false);
    }
  },

  isCheckInTab: Ember.computed('activeTab', function() {
    return this.activeTab === 'check-in';
  }),

  isRecordsTab: Ember.computed('activeTab', function() {
    return this.activeTab === 'records';
  }),

  isMakeupTab: Ember.computed('activeTab', function() {
    return this.activeTab === 'makeup';
  })
});
