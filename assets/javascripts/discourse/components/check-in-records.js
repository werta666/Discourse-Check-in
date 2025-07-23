import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import Component from "@ember/component";

export default Component.extend({
  loading: false,
  records: null,
  pagination: null,
  currentPage: 1,

  didInsertElement() {
    this._super(...arguments);
    this.set('records', []);
    this.set('pagination', {});
    this.send('loadRecords');
  },

  actions: {
    loadRecords(page = 1) {
      this.set('loading', true);
      this.set('currentPage', page);

      ajax("/check-in/check-in-records", {
        data: { page, per_page: 20 }
      }).then((response) => {
        if (response.success) {
          this.setProperties({
            records: response.data.records,
            pagination: response.data.pagination
          });
        }
      }).catch((error) => {
        popupAjaxError(error);
      }).finally(() => {
        this.set('loading', false);
      });
    },

    loadNextPage() {
      if (this.get('pagination.has_more')) {
        this.send('loadRecords', this.currentPage + 1);
      }
    },

    loadPreviousPage() {
      if (this.currentPage > 1) {
        this.send('loadRecords', this.currentPage - 1);
      }
    }
  },

  hasRecords: Ember.computed('records.[]', function() {
    return this.records && this.records.length > 0;
  }),

  showPagination: Ember.computed('pagination.total_count', 'pagination.per_page', function() {
    return this.get('pagination.total_count') > this.get('pagination.per_page');
  }),

  canGoNext: Ember.computed('pagination.has_more', function() {
    return this.get('pagination.has_more');
  }),

  canGoPrevious: Ember.computed('currentPage', function() {
    return this.currentPage > 1;
  }),

  pageInfo: Ember.computed('currentPage', 'pagination.per_page', 'pagination.total_count', function() {
    const start = (this.currentPage - 1) * this.get('pagination.per_page') + 1;
    const end = Math.min(this.currentPage * this.get('pagination.per_page'), this.get('pagination.total_count'));
    return `${start}-${end} of ${this.get('pagination.total_count')}`;
  })
});
