#!/usr/bin/env ruby

def request(cust)
  customer = Customer.find cust
  user = User.find(customer.user_id) if customer.user_id;
  params = { :customers => [], :users => [], :leads => [], :appointments => [] }; 
  lead_ids = [customer.lead.try(:id)]; 
  appointment_ids = customer.appointment_ids.map{|i|Appointment.find_by(id: i) }.compact.map{|i|i.id} + Lead.where(id: lead_ids).map{|l|Appointment.where(id: l.appointment_ids)}.flatten ;
  params[:users] << user.as_json.merge({:customer_ids => user.customer_ids}).merge({:lead_ids => Appointment.find(appointment_ids).map{|a|a.lead_id}.compact}).merge({appointment_ids: appointment_ids}) +  Appintment.where(id: appointment_ids).map{|a|User.find_by(id: a.user_id).as_json}.flatten.compact  if user;
  #customers = Customer.find(customer_ids ? customer_ids : [customer.id]); params[:customers] << customers.map{|c|c.as_json.merge({appointment_ids: c.appointment_ids}).merge(lead_id: c.lead.try(:id))};
  params[:customers] << [customer.as_json.merge(appointment_ids: customer.appointment_ids).merge(lead_id: customer.lead.try(:id))];
  if lead_ids.try(:any?);leads = Lead.find(lead_ids);params[:leads] << leads.map{|l|l.as_json.merge({appointment_ids: l.appointment_ids})}.flatten;end
  if appointment_ids.try(:any?);appointments = Appointment.find(appointment_ids);params[:appointments] << appointments.map{|a|a.as_json}.flatten;end;
  
  params = { :events => params.to_json };
  return params
end

def gen_requests
  Thread.new do
    CustomerJournalItem.where("created_at > ?", Time.now.beginning_of_month - 1.month).map{|i|i.customer_id}.uniq.each{|c_id|
      Net::HTTP.post_form(URI.parse('http://178.157.91.232:4567/api/v1/pass_data'), request(c_id)); 
    sleep 0.01 }
  end
  true
end


# #!/usr/bin/env ruby

# def request(user)
#   user = User.find(user);
#   params = { :customers => [], :users => [], :leads => [], :appointments => [] }; 
#   customer_ids = user.customer_ids; 
#   lead_ids = user.appointments.joins(:lead).map{|a|a.lead_id}; 
#   appointment_ids = user.appointment_ids;
#   params[:users] << user.as_json.merge({:customer_ids => customer_ids}).merge({:lead_ids => lead_ids}).merge({appointment_ids: appointment_ids});
#   if customer_ids.any?;customers = Customer.find(customer_ids); params[:customers] << customers.map{|c|c.as_json.merge({appointment_ids: c.appointment_ids}).merge(lead_id: c.lead.try(:id))};end;
#   if lead_ids.any?;leads = Lead.find(lead_ids);params[:leads] << leads.map{|l|l.as_json.merge({appointment_ids: l.appointment_ids})}.flatten;end
#   if appointment_ids.any?;appointments = Appointment.find(appointment_ids);params[:appointments] << appointments.map{|a|a.as_json}.flatten;end;
  
#   params = { :events => params.to_json };
#   return params
# end

# def gen_requests
#   Thread.new do
#     1000.times{
#       Net::HTTP.post_form(URI.parse('http://192.168.1.48:4567/api/v1/pass_data'), request); 
#     sleep 0.01 }
#   end
#   true
# end




# def gen_recrods; 1000.times{user = User.order(id: :desc).offset(1).first;params = { :customers => [], :users => [], :leads => [], :appointments => [] }; tuser = User.find(rand((user.id - 1)..(user.id + 1))); custemer_ids = tuser.customer_ids; lead_ids = tuser.appointments.joins(:lead).map{|a|a.lead_id}; appointment_ids = tuser.appointment_ids;params[:users] << tuser.as_json.merge({:customer_ids => custemer_ids}).merge({:lead_ids => lead_ids}).merge({appointment_ids: appointment_ids});customer = Customer.find(custemer_ids.sample); params[:customers] << customer.as_json.merge({appointment_ids: customer.appointment_ids}).merge(lead: customer.lead) if customer; lead = Lead.find(lead_ids.sample);params[:leads] << lead.as_json.merge({appointment_ids: lead.appointment_ids}) if lead; appointment = Appointment.find(appointment_ids.sample);params[:appointments] << appointment.as_json if appointment; params = { :events => params.to_json }; x = Net::HTTP.post_form(URI.parse('http://192.168.1.48:4567/api/v1/pass_data'), params); sleep 1 };end


# def gen_recrods
#   1000.times{
#     user = User.order(id: :desc).offset(1).first;
#     params = { :customers => [], :users => [], :leads => [], :appointments => [] }; 
#     tuser = User.find(rand((user.id - 1)..(user.id + 1))); 
#     custemer_ids = tuser.customer_ids; 
#     lead_ids = tuser.appointments.joins(:lead).map{|a|a.lead_id}; 
#     appointment_ids = tuser.appointment_ids;
#     params[:users] << tuser.as_json.merge({:customer_ids => custemer_ids}).merge({:lead_ids => lead_ids}).merge({appointment_ids: appointment_ids});
#     customers = Customer.find(custemer_ids); params[:customers] << customers.map{|c|c.as_json.merge({appointment_ids: c.appointment_ids}).merge(lead: c.lead)} if customers;
#     leads = Lead.find(lead_ids);params[:leads] << leads.map{|l|l.as_json.merge({appointment_ids: l.appointment_ids})} if leads;
#     appointments = Appointment.find(appointment_ids);params[:appointments] << appointments.map(&:as_json) if appointments;
#     params = { :events => params.to_json }; x = Net::HTTP.post_form(URI.parse('http://192.168.1.48:4567/api/v1/pass_data'), params); 
#   sleep 1 }
# end
  