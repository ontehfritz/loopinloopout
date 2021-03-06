class BanksController < ApplicationController
  #before_filter :authenticate_user!
  # GET /sound_banks
  # GET /sound_banks.json
  def index
    luser = Luser.find(:first, :conditions => {:name => params[:username]})
    @luser_banks = LuserBank.find(:all, :conditions => { :luser_id => luser.id})
    @user_name = params[:username]
    @banks = @luser_banks.map { |l| l.bank }
    @sound_files = []
    @user = Luser.find(:first, :conditions => {:name => @user_name})

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @banks }
    end
  end
  
  def download
    require 'zip/zip'
    require 'zip/zipfilesystem'
    bank = Bank.find(params[:id])
    files = bank.bank_files.map { |f| f.sound_file }

    t = Tempfile.new('tmp-zip-' + request.remote_ip)
    Zip::ZipOutputStream.open(t.path) do |zos|
      files.each do |f|
        zos.put_next_entry(f.file_file_name)
        zos.print IO.read(f.file.path)
      end
    end

    send_file t.path, :type => "application/zip", :filename => "#{params[:username]}_#{bank.name}.zip"

    t.close
  end

  def browse
    luser = Luser.find(:first, :conditions => {:name => params[:username]})
    @modal = params[:window]
    @banks = LuserBank.find(:all, :conditions => { :luser_id => luser.id}).map { |b| b.bank }
    @user_name = params[:username];
    @projects = LuserProject.find(:all, :conditions => { :luser_id => luser.id}).map { |p| p.project }
    @user = Luser.find(:first, :conditions => {:name => @user_name})
    @sound_files = []

    respond_to do |format|
      if @modal == "modal"
        format.html { render :layout => false }
      else
        format.html # index.html.erb
        format.json { render json: @banks }
      end
    end
  end
  
  def copy_to
    project = params[:project_id]
    sound_file = params[:sound_file]
    
    sound_file.each do |s|
      ProjectFile.find_or_create_by_sound_file_id_and_project_id(s, project)
      #project_file = ProjectFile.new
      #project_file.sound_file_id = s
      #project_file.project_id = project
      #project_file.save
    end
  end
  
  def update_subtypes
    types = SoundType.find(:all, :conditions => { :sound_type_id => params[:type_id] })
    @t = types.map{|a| [a.name, a.id]}.insert(0, "None")
    
    if(params[:file_id] != "0" and  params[:file_id] != nil)
      @sound_file = SoundFile.find(params[:file_id])
      @sound_file_types = @sound_file.sound_file_types.map {|i| i.sound_type_id }
    end
  end
  
  def update_files
    files = SoundFileType.find(:all, :conditions => { :sound_type_id => params[:type_id] })
    bank_files = BankFile.find(:all, :conditions => { :bank_id => params[:bank_id] })
    @modal = params[:modal]
    @bank = Bank.find(params[:bank_id])
    @user_name = params[:username]
    #files = files + SoundFileType.find(:all, :conditions => {:sound_type_id => params[:sub_type_id]})
    #@sound_files = SoundFile.find(1,2);
    @sound_files = files.map {|f| f.sound_file }
    @sound_files = @sound_files + bank_files.map { |f| f.sound_file }
    @sound_files.uniq!
  end
  
  # GET /banks/1
  # GET /banks/1.json
  def show
    @bank = Bank.find(params[:id])
    bank_files = BankFile.find(:all, :conditions => { :bank_id => params[:id] })
    @sound_file = SoundFile.new
    @sound_files = bank_files.map { |f| f.sound_file }
    @user_name = params[:username]
    @bank_bookmark = BankBookmark.find(:first, :conditions => {:bank_id => @bank.id, :luser_id => current_user.luser.id})
    @user = Luser.find(:first, :conditions => {:name => @user_name})
    @banks = current_user.luser.banks

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @bank }
    end
  end
  
  

  # GET /sound_banks/new
  # GET /sound_banks/new.json
  def new
    @bank = Bank.new
    @user_name = params[:username]
    @user = Luser.find(:first, :conditions => {:name => @user_name})
    

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @bank }
    end
  end

  # GET /sound_banks/1/edit
  def edit
    @bank = Bank.find(params[:id])
  end

  def copy
    @bank = Bank.find(params[:id])
    
    respond_to do |format|
      if Bank.copy(@bank, current_user.luser)
        format.html { redirect_to bank_url(current_user.luser.name, @bank), notice: 'Sound bank was successfully copied.' }
        format.json { render json: @bank, status: :created, location: @bank }
      end
    end
  end
  
  def copy_files
    bank = Bank.find(params[:bank_id])
    sound_file = SoundFile.find(params[:sound_file])
    
    sound_file.each do |s|
      SoundFile.copy_to_bank(s, bank)
    end
  end
  
  # POST /sound_banks
  # POST /sound_banks.json
  def create
    @bank = Bank.new(params[:bank])
    @bank.created_by = current_user.luser.name

    respond_to do |format|
      if @bank.save
        luser_bank = LuserBank.new
        luser_bank.bank_id = @bank.id
        luser_bank.luser_id = current_user.luser.id
        luser_bank.save
        
        Activity.CreatedBank(current_user.luser, @bank)
        
        format.html { redirect_to bank_url(current_user.luser.name, @bank), notice: 'Sound bank was successfully created.' }
        format.json { render json: @bank, status: :created, location: @bank }
      else
        format.html { render action: "new" }
        format.json { render json: @bank.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /sound_banks/1
  # PUT /sound_banks/1.json
  def update
    @bank = Bank.find(params[:id])
    genres = params[:genres].strip
    
    respond_to do |format|
      if @bank.update_attributes(params[:bank])
        Genre.add_bank_genres(@bank, genres)
        format.html { redirect_to @bank, notice: 'Sound bank was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @bank.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sound_banks/1
  # DELETE /sound_banks/1.json
  def destroy
    @bank = Bank.find(params[:id])
    @bank.destroy

    respond_to do |format|
      format.html { redirect_to banks_url }
      format.json { head :no_content }
    end
  end
end
