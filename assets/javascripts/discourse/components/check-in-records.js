import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class CheckInRecords extends Component {
  @service currentUser;
  
  @tracked loading = false;
  @tracked records = [];
  @tracked pagination = {};
  @tracked currentPage = 1;

  constructor() {
    super(...arguments);
    this.loadRecords();
  }

  @action
  async loadRecords(page = 1) {
    this.loading = true;
    this.currentPage = page;
    
    try {
      const response = await ajax("/check-in/check-in-records", {
        data: { page, per_page: 20 }
      });

      if (response.success) {
        this.records = response.data.records;
        this.pagination = response.data.pagination;
      }
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.loading = false;
    }
  }

  @action
  loadNextPage() {
    if (this.pagination.has_more) {
      this.loadRecords(this.currentPage + 1);
    }
  }

  @action
  loadPreviousPage() {
    if (this.currentPage > 1) {
      this.loadRecords(this.currentPage - 1);
    }
  }

  get hasRecords() {
    return this.records && this.records.length > 0;
  }

  get showPagination() {
    return this.pagination.total_count > this.pagination.per_page;
  }

  get canGoNext() {
    return this.pagination.has_more;
  }

  get canGoPrevious() {
    return this.currentPage > 1;
  }

  get pageInfo() {
    const start = (this.currentPage - 1) * this.pagination.per_page + 1;
    const end = Math.min(this.currentPage * this.pagination.per_page, this.pagination.total_count);
    return `${start}-${end} of ${this.pagination.total_count}`;
  }
}
